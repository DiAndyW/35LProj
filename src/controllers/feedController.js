import MoodCheckIn from '../models/CheckIn.js';
import User from '../models/UserModel.js';
import mongoose from 'mongoose';

export const getBlockedUsers = async (userId) => {
    const user = await User.findById(userId).select('blockedUsers');
    const myBlockedIds = user?.blockedUsers || [];
    const usersWhoBlockedMe = await User.find({ blockedUsers: userId }).select('_id');
    const idsWhoBlockedMe = usersWhoBlockedMe.map(user => user._id.toString());

    const uniqueBlockedIds = new Set([...myBlockedIds, ...idsWhoBlockedMe]);
    return Array.from(uniqueBlockedIds); 
}

export const getFeedCheckIns = async (req, res) => {
    try {
        const userId = req.user.sub;
        const blockedUsers = await getBlockedUsers(userId);

        const sortQuery = req.query.sort || 'timestamp';
        const validSorts = ['timestamp', 'hottest', 'relevance'];
        
        if (!validSorts.includes(sortQuery)) {
            return res.status(400).json({ 
                error: `Invalid sort method. Use: ${validSorts.join(', ')}` 
            });
        }

        const skip = Math.max(parseInt(req.query.skip, 10) || 0, 0);
        const limit = Math.min(parseInt(req.query.limit, 10) || 20, 100);

        let checkIns;

        if (sortQuery === 'hottest') {
            // Use aggregation to sort by array lengths
            checkIns = await MoodCheckIn.aggregate([
                {
                    $match: {
                        privacy: 'public',
                        userId: { $nin: blockedUsers }
                    }
                },
                {
                    $addFields: {
                        likesCount: { $size: "$likes" },
                        commentsCount: { $size: "$comments" },
                        // Combined popularity score: likes + (comments * 2)
                        popularityScore: {
                            $add: [
                                { $size: "$likes" },
                                { $multiply: [{ $size: "$comments" }, 2] }
                            ]
                        }
                    }
                },
                {
                    $sort: { 
                        popularityScore: -1,  // Sort by popularity first
                        timestamp: -1         // Then by recency for ties
                    }
                },
                {
                    $skip: skip
                },
                {
                    $limit: limit
                }
            ]);

            console.log(`Popular sort: Found ${checkIns.length} posts`);
            
        } else if (sortQuery === 'relevance') {
            // Relevance algorithm using aggregation
            checkIns = await MoodCheckIn.aggregate([
                {
                    $match: {
                        privacy: 'public',
                        userId: { $nin: blockedUsers.map(id => mongoose.Types.ObjectId(id)) }
                    }
                },
                {
                    $addFields: {
                        likesCount: { $size: "$likes" },
                        commentsCount: { $size: "$comments" },
                        ageInHours: {
                            $divide: [
                                { $subtract: [new Date(), "$timestamp"] },
                                1000 * 60 * 60
                            ]
                        }
                    }
                },
                {
                    $addFields: {
                        relevanceScore: {
                            $add: [
                                // Recency score (decays over time)
                                {
                                    $multiply: [
                                        { $max: [0, { $subtract: [100, { $multiply: ["$ageInHours", 0.5] }] }] },
                                        0.4
                                    ]
                                },
                                // Likes score
                                { $multiply: ["$likesCount", 0.8] },
                                // Comments score
                                { $multiply: ["$commentsCount", 1.2] }
                            ]
                        }
                    }
                },
                {
                    $sort: { relevanceScore: -1 }
                },
                {
                    $skip: skip
                },
                {
                    $limit: limit
                }
            ]);

        } else {
            // Default timestamp sorting
            checkIns = await MoodCheckIn.find({
                privacy: 'public',
                userId: { $nin: blockedUsers }
            })
            .sort({ timestamp: -1 })
            .skip(skip)
            .limit(limit);
        }

        // Convert to response format
        const responseData = checkIns.map(checkIn => {
            // For aggregation results, manually create the response
            if (sortQuery === 'hottest' || sortQuery === 'relevance') {
                return {
                    _id: checkIn._id,
                    userId: checkIn.userId,
                    emotion: {
                        name: checkIn.emotion.name,
                        attributes: checkIn.emotion.attributes
                    },
                    reason: checkIn.reason,
                    people: checkIn.people,
                    activities: checkIn.activities,
                    privacy: checkIn.privacy,
                    location: checkIn.location?.landmarkName ? {
                        name: checkIn.location.landmarkName,
                        coordinates: checkIn.location.coordinates?.coordinates,
                        isShared: checkIn.location.isShared
                    } : null,
                    timestamp: checkIn.timestamp,
                    isAnonymous: checkIn.privacy === 'private',
                    createdAt: checkIn.createdAt,
                    updatedAt: checkIn.updatedAt,
                    likes: {
                        count: checkIn.likes.length,
                        userIds: checkIn.likes
                    },
                    comments: {
                        count: checkIn.comments.length,
                        data: checkIn.comments.map(comment => ({
                            userId: comment.userId,
                            content: comment.content,
                            timestamp: comment.timestamp
                        }))
                    }
                };
            }
            
            // For regular find() queries, use the virtual
            return checkIn.displayData;
        });

        res.json(responseData);

    } catch (error) {
        console.error('Feed fetch error:', error);
        res.status(500).json({ error: 'Failed to fetch feed', details: error.message });
    }
}