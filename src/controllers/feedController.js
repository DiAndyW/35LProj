import MoodCheckIn from '../models/CheckIn.js';
import User from '../models/UserModel.js';

const getBlockedUsers = async (userId) => {
    // returns ids of blocked users and users blocked by the user
    
    // first get ids blocked by user
    const user = await User.findById(userId).select('blockedUsers');
    const myBlockedIds = user?.blockedUsers || [];
    // then get ids of users who blocked the user
    const usersWhoBlockedMe = await User.find({ blockedUsers: userId }).select('_id');
    const idsWhoBlockedMe = usersWhoBlockedMe.map(user => user._id.toString());

    // return unique blocked user IDs
    const uniqueBlockedIds = new Set([...myBlockedIds, ...idsWhoBlockedMe]);
    return Array.from(uniqueBlockedIds); 
}

export const getFeedCheckIns = async (req, res) => {
    try {
        const userId = req.user.sub;
        // Fetch blocked users for the current user
        const blockedUsers = await getBlockedUsers(userId);

        // sort by hottest (most liked) or recent (timestamp)
        const sortQuery = req.query.sort || 'timestamp';
        if (sortQuery !== 'timestamp' && sortQuery !== 'hottest') {
            return res.status(400).json({ error: 'Invalid sort method. Use "timestamp" or "hottest".' });
        }
        const sortMethod = (sortQuery === 'hottest' ? { 'likes.count': -1 } : { timestamp: -1 });

        // Parse skip and limit from query, with defaults
        const skip = Math.max(parseInt(req.query.skip, 10) || 0, 0);
        const limit = Math.min(parseInt(req.query.limit, 10) || 20, 100);

        const checkIns = await MoodCheckIn.find(
                { 
                    privacy: 'public', 
                    userId: { $nin: blockedUsers }  // Exclude blocked users
                }
            )
            .sort(sortMethod)
            .skip(skip)
            .limit(limit);

        const responseData = checkIns.map(checkIn => checkIn.displayData);

        res.json(responseData);
    } catch (error) {
        res.status(500).json({ error: 'Failed to fetch feed', details: error.message });
    }
}