import { Router } from 'express';
import MoodPost from '../models/MoodPost.js'; // Ensure this path is correct
import mongoose from 'mongoose'; // Import mongoose for ObjectId validation

const mapRouter = Router();

// --- HELPER FUNCTIONS ---

const calculateDistance = (lat1, lng1, lat2, lng2) => {
  const R = 6371; // Radius of the earth in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLng / 2) * Math.sin(dLng / 2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  return R * c; // Distance in km
};

const isValidCoordinate = (lat, lng) => {
  const numLat = parseFloat(lat);
  const numLng = parseFloat(lng);
  return !isNaN(numLat) && numLat >= -90 && numLat <= 90 &&
    !isNaN(numLng) && numLng >= -180 && numLng <= 180;
};

// Refined getMostFrequentEmotionObject: expects an array of emotion objects, returns the dominant emotion object
function getMostFrequentEmotionObject(emotionObjects) {
  if (!emotionObjects || emotionObjects.length === 0) return null;
  const nameCounts = {};
  let maxCount = 0;
  let dominantEmotion = emotionObjects[0]; // Default to the first emotion object

  emotionObjects.forEach(emo => {
    if (emo && typeof emo.name === 'string') {
      nameCounts[emo.name] = (nameCounts[emo.name] || 0) + 1;
      if (nameCounts[emo.name] > maxCount) {
        maxCount = nameCounts[emo.name];
        dominantEmotion = emo; // Store the whole object
      }
    }
  });
  return dominantEmotion; // Return the whole emotion object
}

// Refined clusterMoodPosts:
function clusterMoodPosts(posts, zoomLevel) {
  // Filter for posts that have valid coordinate data before attempting to cluster
  const validPosts = posts.filter(p =>
    p.location &&
    p.location.coordinates &&
    p.location.coordinates.coordinates &&
    Array.isArray(p.location.coordinates.coordinates) &&
    p.location.coordinates.coordinates.length === 2 &&
    typeof p.location.coordinates.coordinates[0] === 'number' &&
    typeof p.location.coordinates.coordinates[1] === 'number'
  );

  if (validPosts.length !== posts.length) {
    console.warn("Some posts were excluded from clustering due to missing/invalid location data.");
  }
  if (validPosts.length === 0) return [];

  const clusters = [];
  const processed = new Set();
  // Adjust baseRadius and zoom factor for desired clustering sensitivity
  const baseRadius = 50; // km at zoom level 0
  const clusterRadius = Math.max(0.1, baseRadius / Math.pow(2, zoomLevel)); // Ensure a minimum radius

  validPosts.forEach((post, i) => {
    if (processed.has(i)) return;

    // Extract emotion name, default if emotion or name is missing
    const initialEmotionName = (post.emotion && typeof post.emotion.name === 'string') ? post.emotion.name : 'Unknown';

    const currentCluster = {
      postsInCluster: [post],
      emotionNamesInCluster: [initialEmotionName] // Store names for finding dominant emotion name
    };
    processed.add(i);

    for (let j = i + 1; j < validPosts.length; j++) {
      if (processed.has(j)) continue;
      const otherPost = validPosts[j];
      const distance = calculateDistance(
        post.location.coordinates.coordinates[1],    // lat1
        post.location.coordinates.coordinates[0],    // lng1
        otherPost.location.coordinates.coordinates[1], // lat2
        otherPost.location.coordinates.coordinates[0]  // lng2
      );

      if (distance <= clusterRadius) {
        currentCluster.postsInCluster.push(otherPost);
        const otherEmotionName = (otherPost.emotion && typeof otherPost.emotion.name === 'string') ? otherPost.emotion.name : 'Unknown';
        currentCluster.emotionNamesInCluster.push(otherEmotionName);
        processed.add(j);
      }
    }

    if (currentCluster.postsInCluster.length > 1) {
      const avgLat = currentCluster.postsInCluster.reduce((sum, p) => sum + p.location.coordinates.coordinates[1], 0) / currentCluster.postsInCluster.length;
      const avgLng = currentCluster.postsInCluster.reduce((sum, p) => sum + p.location.coordinates.coordinates[0], 0) / currentCluster.postsInCluster.length;
      
      // Find the most frequent emotion *name*
      const dominantEmotionNameStr = getMostFrequentEmotionObject(currentCluster.emotionNamesInCluster.map(name => ({name})))?.name || 'Unknown';
      // Find the first full emotion object that matches the dominant name
      const representativeEmotionObject = currentCluster.postsInCluster.find(p => p.emotion && p.emotion.name === dominantEmotionNameStr)?.emotion || currentCluster.postsInCluster[0].emotion;

      clusters.push({
        id: `cluster_${avgLng.toFixed(5)}_${avgLat.toFixed(5)}_${currentCluster.postsInCluster.length}`,
        type: 'cluster',
        location: { // GeoJSON structure for location
          landmarkName: "Cluster", // Or derive a name if possible
          coordinates: {
            type: 'Point',
            coordinates: [avgLng, avgLat]
          }
        },
        count: currentCluster.postsInCluster.length,
        emotion: representativeEmotionObject, // Use a representative full emotion object
        // Note: Swift client needs to handle 'cluster' type differently from 'single' type post.
        // It won't have all fields of a MapMoodPost (e.g., reason, userId).
      });
    } else {
      // Single post, not clustered (it's the 'post' object from the input array)
      clusters.push({
        ...post, // 'post' is already transformed with likesCount, commentsCount etc.
        id: post._id.toString(), // Ensure 'id' is the string representation of _id
        type: 'single'
      });
    }
  });
  return clusters;
}


// --- API ENDPOINTS ---

/**
 * GET /api/map/moods
 * Fetch mood posts within map viewport bounds (Refined for Swift Client)
 */
mapRouter.get('/moods', async (req, res) => {
  try {
    const {
      swLat, swLng, neLat, neLng,
      centerLat, centerLng,
      since,
      limit = '500',
      privacy = 'public', // Note: current query only fetches 'public'
      cluster = 'false',
      zoomLevel = '10'
    } = req.query;

    console.log('Received /moods request with query params:', req.query);

    if (!swLat || !swLng || !neLat || !neLng) {
      console.error('Validation Error: Map boundary coordinates missing');
      return res.status(400).json({
        success: false,
        error: 'Map boundary coordinates required'
      });
    }

    const bounds = {
      sw: { lat: parseFloat(swLat), lng: parseFloat(swLng) },
      ne: { lat: parseFloat(neLat), lng: parseFloat(neLng) }
    };

    if (!isValidCoordinate(bounds.sw.lat, bounds.sw.lng) ||
        !isValidCoordinate(bounds.ne.lat, bounds.ne.lng)) {
      console.error('Validation Error: Invalid coordinates received:', bounds);
      return res.status(400).json({
        success: false,
        error: 'Invalid coordinates'
      });
    }
    
    console.log('Parsed map bounds:', bounds);

    const queryConditions = {
      $or: [{ privacy: 'public' }], // Consider expanding privacy logic if needed
    };

    const minLat = Math.min(bounds.sw.lat, bounds.ne.lat);
    const maxLat = Math.max(bounds.sw.lat, bounds.ne.lat);
    const minLng = Math.min(bounds.sw.lng, bounds.ne.lng);
    const maxLng = Math.max(bounds.sw.lng, bounds.ne.lng);

    queryConditions['location.coordinates'] = {
      $geoWithin: {
        $box: [
          [minLng, minLat],
          [maxLng, maxLat]
        ]
      }
    };

    if (since) {
      const sinceDate = new Date(since);
      if (!isNaN(sinceDate.getTime())) {
        queryConditions.timestamp = { $gte: sinceDate };
      } else {
        console.warn('Invalid "since" date format received:', since);
        const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
        queryConditions.timestamp = { $gte: sevenDaysAgo }; // Fallback to default
      }
    } else {
      const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
      queryConditions.timestamp = { $gte: sevenDaysAgo };
    }

    const parsedLimit = parseInt(limit);
    const finalLimit = isNaN(parsedLimit) || parsedLimit <= 0 ? 500 : parsedLimit;

    console.log('Executing MoodPost.find() with query:', JSON.stringify(queryConditions, null, 2));

    // Fetch mood posts - UPDATED .select()
    let moodPostsFromDB = await MoodPost.find(queryConditions)
      .sort({ timestamp: -1 })
      .limit(finalLimit)
      .select('_id userId emotion reason location timestamp privacy isAnonymous likes comments people activities') // Ensure all needed fields are here
      .populate('userId', 'username profilePicture _id') // Ensure _id is populated for UserBrief
      .lean();

    console.log(`Found ${moodPostsFromDB.length} mood posts from DB.`);

    // --- TRANSFORM DATA to include counts and ensure all fields for Swift model ---
    let moodPosts = moodPostsFromDB.map(post => {
      return {
        _id: post._id, // Swift model expects to map "_id" to "id"
        userId: post.userId, // Populated user object
        emotion: post.emotion,
        reason: post.reason,
        location: post.location,
        timestamp: post.timestamp, // Mongoose converts Date to ISO string on JSON.stringify
        privacy: post.privacy,
        isAnonymous: post.isAnonymous === undefined ? false : post.isAnonymous, // Default if not present
        likesCount: Array.isArray(post.likes) ? post.likes.length : 0,
        commentsCount: Array.isArray(post.comments) ? post.comments.length : 0,
        people: Array.isArray(post.people) ? post.people : [],
        activities: Array.isArray(post.activities) ? post.activities : [],
        // distance will be added in the next step if centerLat/Lng are provided
      };
    });

    // Calculate distance from center if provided
    if (centerLat && centerLng) {
      const center = {
        lat: parseFloat(centerLat),
        lng: parseFloat(centerLng)
      };

      if (isValidCoordinate(center.lat, center.lng)) {
        moodPosts = moodPosts.map(post => {
          // Ensure post.location and coordinates exist before trying to access them
          if (post.location && post.location.coordinates && post.location.coordinates.coordinates &&
              Array.isArray(post.location.coordinates.coordinates) && post.location.coordinates.coordinates.length === 2) {
            return {
              ...post,
              distance: calculateDistance(
                center.lat, center.lng,
                post.location.coordinates.coordinates[1], // lat
                post.location.coordinates.coordinates[0]  // lng
              )
            };
          }
          return post; // Return post unmodified if location data is invalid/missing
        });
      } else {
        console.warn('Invalid centerLat/centerLng for distance calculation:', centerLat, centerLng);
      }
    }

    let responseData = moodPosts;
    const parsedZoomLevel = parseInt(zoomLevel);

    if (cluster === 'true' && !isNaN(parsedZoomLevel) && parsedZoomLevel < 15) {
      responseData = clusterMoodPosts(moodPosts, parsedZoomLevel); // Pass the transformed moodPosts
    } else if (cluster === 'true') {
      console.warn(`Clustering requested but zoomLevel ("${zoomLevel}") is invalid or too high. Serving unclustered data.`);
    }

    res.json({
      success: true,
      count: responseData.length,
      viewport: bounds,
      actualBounds: { minLat, minLng, maxLat, maxLng },
      clustered: cluster === 'true' && !isNaN(parsedZoomLevel) && parsedZoomLevel < 15,
      filtersApplied: {
        timestamp: queryConditions.timestamp,
        privacy: queryConditions.$or.map(p => p.privacy).filter(Boolean)
      },
      data: responseData
    });

  } catch (error) {
    console.error('Error fetching map moods:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch mood posts',
      details: error.message
    });
  }
});


/**
 * GET /api/map/moods/heatmap
 * Get aggregated mood data for heatmap visualization
 */
mapRouter.get('/moods/heatmap', async (req, res) => {
  try {
    const { swLat, swLng, neLat, neLng, gridSize = '50' } = req.query; // gridSize as string from query

    if (!isValidCoordinate(swLat, swLng) || !isValidCoordinate(neLat, neLng)) {
      return res.status(400).json({ success: false, error: 'Valid boundary coordinates required' });
    }
    
    const finalGridSize = parseInt(gridSize);
    if (isNaN(finalGridSize) || finalGridSize <= 0) {
        return res.status(400).json({ success: false, error: 'Invalid gridSize parameter' });
    }

    const bounds = {
      sw: { lat: parseFloat(swLat), lng: parseFloat(swLng) },
      ne: { lat: parseFloat(neLat), lng: parseFloat(neLng) }
    };

    // Prevent division by zero if lat/lng span is zero
    const latSpan = bounds.ne.lat - bounds.sw.lat;
    const lngSpan = bounds.ne.lng - bounds.sw.lng;

    if (latSpan === 0 || lngSpan === 0) {
        // Handle case with no span (single point or line) - perhaps return empty or single point
        return res.json({ success: true, gridSize: finalGridSize, bounds, data: [] });
    }

    const heatmapData = await MoodPost.aggregate([
      {
        $match: {
          'location.coordinates': {
            $geoWithin: {
              $box: [
                [bounds.sw.lng, bounds.sw.lat],
                [bounds.ne.lng, bounds.ne.lat]
              ]
            }
          },
          privacy: 'public', // Consider other privacy settings if needed
          timestamp: { $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) } // Example: last 7 days
        }
      },
      {
        $project: {
          _id: 0, // Exclude original _id
          lat: { $arrayElemAt: ['$location.coordinates.coordinates', 1] },
          lng: { $arrayElemAt: ['$location.coordinates.coordinates', 0] },
          emotion: '$emotion' // Project the whole emotion object
        }
      },
      {
        $group: {
          _id: { // Grid cell identifier
            latBucket: {
              $floor: {
                $multiply: [
                  { $divide: [{ $subtract: ['$lat', bounds.sw.lat] }, latSpan] },
                  finalGridSize
                ]
              }
            },
            lngBucket: {
              $floor: {
                $multiply: [
                  { $divide: [{ $subtract: ['$lng', bounds.sw.lng] }, lngSpan] },
                  finalGridSize
                ]
              }
            }
          },
          count: { $sum: 1 },
          emotionsInBucket: { $push: '$emotion' } // Push full emotion objects
        }
      }
    ]);

    const points = heatmapData.map(cell => {
      const latStep = latSpan / finalGridSize;
      const lngStep = lngSpan / finalGridSize;
      
      return {
        lat: bounds.sw.lat + (cell._id.latBucket + 0.5) * latStep,
        lng: bounds.sw.lng + (cell._id.lngBucket + 0.5) * lngStep,
        intensity: cell.count,
        // Get the full dominant emotion object for the cell
        dominantEmotion: getMostFrequentEmotionObject(cell.emotionsInBucket) 
      };
    }).filter(p => !isNaN(p.lat) && !isNaN(p.lng)); // Filter out any NaN results from bucketing

    res.json({
      success: true,
      gridSize: finalGridSize,
      bounds,
      data: points
    });

  } catch (error) {
    console.error('Error generating heatmap:', error);
    res.status(500).json({ success: false, error: 'Failed to generate heatmap data', details: error.message });
  }
});

/**
 * GET /api/map/moods/:id
 * Get detailed information about a specific mood post
 */
mapRouter.get('/moods/:id', async (req, res) => {
  try {
    const { id } = req.params;
    if (!mongoose.Types.ObjectId.isValid(id)) {
        return res.status(400).json({ success: false, error: 'Invalid mood post ID format' });
    }

    const moodPost = await MoodPost.findById(id)
      .populate('userId', '_id username profilePicture bio') // bio is extra, UserBrief needs _id
      // .populate('comments.userId', '_id username profilePicture') // If you have detailed comments
      .lean(); // Use lean for plain JS object

    if (!moodPost) {
      return res.status(404).json({ success: false, error: 'Mood post not found' });
    }

    // Add privacy logic here if the post isn't public
    // e.g., if (moodPost.privacy !== 'public' && (!req.user || moodPost.userId._id.toString() !== req.user.id)) { ... }
    
    const responseData = {
      _id: moodPost._id,
      id: moodPost._id.toString(), // For Swift client
      userId: moodPost.userId ? {
        _id: moodPost.userId._id,
        id: moodPost.userId._id.toString(),
        username: moodPost.userId.username,
        profilePicture: moodPost.userId.profilePicture,
        // bio: moodPost.userId.bio // if client needs it
      } : null,
      emotion: moodPost.emotion,
      reason: moodPost.reason,
      location: moodPost.location,
      timestamp: moodPost.timestamp,
      privacy: moodPost.privacy,
      isAnonymous: typeof moodPost.isAnonymous === 'boolean' ? moodPost.isAnonymous : false,
      likesCount: Array.isArray(moodPost.likes) ? moodPost.likes.length : 0,
      commentsCount: Array.isArray(moodPost.comments) ? moodPost.comments.length : 0,
      people: Array.isArray(moodPost.people) ? moodPost.people : [],
      activities: Array.isArray(moodPost.activities) ? moodPost.activities : [],
      // You might want to include full 'likes' or 'comments' arrays if the detail view needs them
      // likes: moodPost.likes, 
      // comments: moodPost.comments, // if comments are populated with details
      createdAt: moodPost.createdAt, // often useful for detail views
      updatedAt: moodPost.updatedAt,
    };

    res.json({ success: true, data: responseData });

  } catch (error) {
    console.error(`Error fetching mood post /moods/${req.params.id}:`, error);
    if (error.name === 'CastError') { // Should be caught by ObjectId.isValid now
      return res.status(400).json({ success: false, error: 'Invalid mood post ID' });
    }
    res.status(500).json({ success: false, error: 'Failed to fetch mood post', details: error.message });
  }
});


/**
 * GET /api/map/moods/nearby/:lat/:lng
 * Get mood posts near a specific location
 */
mapRouter.get('/moods/nearby/:lat/:lng', async (req, res) => {
  try {
    const lat = parseFloat(req.params.lat);
    const lng = parseFloat(req.params.lng);
    const maxDistanceInMeters = parseFloat(req.query.maxDistance) || 5000; // Default 5km
    const limit = parseInt(req.query.limit) || 50;

    if (!isValidCoordinate(lat, lng)) {
      return res.status(400).json({ success: false, error: 'Invalid coordinates' });
    }

    const nearbyPosts = await MoodPost.aggregate([
      {
        $geoNear: {
          near: { type: 'Point', coordinates: [lng, lat] },
          distanceField: 'distanceData.calculated', // distance in meters
          maxDistance: maxDistanceInMeters,
          spherical: true,
          // Query can be used to pre-filter documents before distance calculation
          query: {
            privacy: 'public', // Example filter
            timestamp: { $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) } // Example: last 30 days
          }
        }
      },
      { $sort: { 'distanceData.calculated': 1 } }, // Sort by distance
      { $limit: limit },
      { // Lookup user details
        $lookup: {
          from: 'users', // collection name for users
          localField: 'userId',
          foreignField: '_id',
          as: 'userData'
        }
      },
      { // Deconstruct the userData array (should be single element)
        $unwind: { path: '$userData', preserveNullAndEmptyArrays: true } // preserve if user not found
      },
      { // Project the final shape
        $project: {
          _id: 1,
          emotion: 1, reason: 1, location: 1, timestamp: 1, privacy: 1, isAnonymous: 1,
          likes: 1, comments: 1, people: 1, activities: 1, // Include arrays for counts
          userIdObj: '$userData', // Keep the user object for transformation
          distance: '$distanceData.calculated' // The calculated distance in meters
        }
      }
    ]);

    const transformedPosts = nearbyPosts.map(post => ({
      _id: post._id,
      id: post._id.toString(),
      userId: post.userIdObj ? {
        _id: post.userIdObj._id,
        id: post.userIdObj._id.toString(),
        username: post.userIdObj.username,
        profilePicture: post.userIdObj.profilePicture
      } : null,
      emotion: post.emotion,
      reason: post.reason,
      location: post.location,
      timestamp: post.timestamp,
      privacy: post.privacy,
      isAnonymous: typeof post.isAnonymous === 'boolean' ? post.isAnonymous : false,
      // Distance in KM for client, as used in /moods endpoint
      distance: post.distance / 1000, // Convert meters to km
      likesCount: Array.isArray(post.likes) ? post.likes.length : 0,
      commentsCount: Array.isArray(post.comments) ? post.comments.length : 0,
      people: Array.isArray(post.people) ? post.people : [],
      activities: Array.isArray(post.activities) ? post.activities : [],
    }));

    res.json({
      success: true,
      center: { lat, lng },
      maxDistance: maxDistanceInMeters / 1000, // km
      count: transformedPosts.length,
      data: transformedPosts
    });

  } catch (error) {
    console.error('Error fetching nearby moods:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch nearby mood posts', details: error.message });
  }
});

/**
 * GET /api/map/stats
 * Get statistics about mood posts in an area
 */
mapRouter.get('/stats', async (req, res) => {
  try {
    const { swLat, swLng, neLat, neLng } = req.query;

    if (!isValidCoordinate(swLat, swLng) || !isValidCoordinate(neLat, neLng)) {
      return res.status(400).json({ success: false, error: 'Valid boundary coordinates required' });
    }
    
    const bounds = {
      sw: { lat: parseFloat(swLat), lng: parseFloat(swLng) },
      ne: { lat: parseFloat(neLat), lng: parseFloat(neLng) }
    };
    
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

    // First, get the basic stats and emotion names
    const basicStats = await MoodPost.aggregate([
      {
        $match: {
          'location.coordinates': {
            $geoWithin: {
              $box: [
                [bounds.sw.lng, bounds.sw.lat],
                [bounds.ne.lng, bounds.ne.lat]
              ]
            }
          },
          privacy: 'public',
          timestamp: { $gte: thirtyDaysAgo }
        }
      },
      {
        $group: {
          _id: null,
          totalPosts: { $sum: 1 },
          emotionNames: { $push: '$emotion.name' }
        }
      }
    ]);

    if (!basicStats || basicStats.length === 0) {
      // No posts found in the area
      return res.json({
        success: true,
        bounds,
        data: {
          totalPosts: 0,
          emotionBreakdown: {},
          postsPerDay: 0
        }
      });
    }

    const { totalPosts, emotionNames } = basicStats[0];

    // Count emotion occurrences
    const emotionBreakdown = {};
    emotionNames.forEach(emotionName => {
      if (emotionName && typeof emotionName === 'string') {
        emotionBreakdown[emotionName] = (emotionBreakdown[emotionName] || 0) + 1;
      }
    });

    // Calculate posts per day
    const postsPerDay = totalPosts > 0 ? totalPosts / 30 : 0;

    const result = {
      totalPosts,
      emotionBreakdown,
      postsPerDay: Number(postsPerDay.toFixed(2))
    };

    res.json({
      success: true,
      bounds,
      data: result
    });

  } catch (error) {
    console.error('Error fetching map stats:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch statistics', 
      details: error.message 
    });
  }
});

// Alternative implementation using a more complex aggregation if you prefer:
// This version does everything in one aggregation pipeline
mapRouter.get('/stats-advanced', async (req, res) => {
  try {
    const { swLat, swLng, neLat, neLng } = req.query;

    if (!isValidCoordinate(swLat, swLng) || !isValidCoordinate(neLat, neLng)) {
      return res.status(400).json({ success: false, error: 'Valid boundary coordinates required' });
    }
    
    const bounds = {
      sw: { lat: parseFloat(swLat), lng: parseFloat(swLng) },
      ne: { lat: parseFloat(neLat), lng: parseFloat(neLng) }
    };
    
    const thirtyDaysAgo = new Date(Date.now() - 30 * 24 * 60 * 60 * 1000);

    const statsResult = await MoodPost.aggregate([
      {
        $match: {
          'location.coordinates': {
            $geoWithin: {
              $box: [
                [bounds.sw.lng, bounds.sw.lat],
                [bounds.ne.lng, bounds.ne.lat]
              ]
            }
          },
          privacy: 'public',
          timestamp: { $gte: thirtyDaysAgo }
        }
      },
      {
        $group: {
          _id: '$emotion.name', // Group by emotion name
          count: { $sum: 1 }
        }
      },
      {
        $group: {
          _id: null,
          totalPosts: { $sum: '$count' },
          emotions: {
            $push: {
              name: '$_id',
              count: '$count'
            }
          }
        }
      },
      {
        $project: {
          _id: 0,
          totalPosts: 1,
          emotionBreakdown: {
            $arrayToObject: {
              $map: {
                input: '$emotions',
                as: 'emotion',
                in: {
                  k: '$$emotion.name',
                  v: '$$emotion.count'
                }
              }
            }
          },
          postsPerDay: {
            $cond: {
              if: { $eq: ['$totalPosts', 0] },
              then: 0,
              else: { $round: [{ $divide: ['$totalPosts', 30] }, 2] }
            }
          }
        }
      }
    ]);
    
    res.json({
      success: true,
      bounds,
      data: statsResult[0] || {
        totalPosts: 0,
        emotionBreakdown: {},
        postsPerDay: 0
      }
    });

  } catch (error) {
    console.error('Error fetching map stats (advanced):', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch statistics', 
      details: error.message 
    });
  }
});


// Ensure 2dsphere index exists for geospatial queries on MoodPost model
// This should be done once when your application starts or during DB setup.
// Example: MoodPost.collection.createIndex({ 'location.coordinates': '2dsphere' })
//   .then(() => console.log("2dsphere index ensured for location.coordinates"))
//   .catch(err => console.error("Error ensuring 2dsphere index:", err));

export default mapRouter;