import { Router } from 'express';
import MoodPost from '../models/MoodPost.js'; // Ensure this path is correct

const mapRouter = Router();

// Helper function to calculate distance between two points (remains the same)
const calculateDistance = (lat1, lng1, lat2, lng2) => {
  const R = 6371; // Radius of the earth in km
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a =
    Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLng/2) * Math.sin(dLng/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c; // Distance in km
};

// Validate coordinates (remains the same)
const isValidCoordinate = (lat, lng) => {
  const numLat = parseFloat(lat);
  const numLng = parseFloat(lng);
  return !isNaN(numLat) && numLat >= -90 && numLat <= 90 &&
         !isNaN(numLng) && numLng >= -180 && numLng <= 180;
};

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

// Helper function to cluster mood posts (Modified to ensure `id` uses `_id`)
function clusterMoodPosts(posts, zoomLevel) {
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
  const baseRadius = 50;
  const clusterRadius = Math.max(0.1, baseRadius / Math.pow(2, zoomLevel));

  validPosts.forEach((post, i) => {
    if (processed.has(i)) return;

    // Ensure post.emotion is an object with a name, or handle potential variations
    const initialEmotionName = (post.emotion && typeof post.emotion.name === 'string') ? post.emotion.name : 'Unknown';

    const cluster = {
      type: 'cluster',
      location: JSON.parse(JSON.stringify(post.location)), // Deep copy
      postsInCluster: [post],
      // Storing emotion names for dominant emotion calculation
      emotionNamesInCluster: [initialEmotionName] 
    };
    processed.add(i);

    for (let j = i + 1; j < validPosts.length; j++) {
      if (processed.has(j)) continue;
      const otherPost = validPosts[j];
      const distance = calculateDistance(
        post.location.coordinates.coordinates[1],
        post.location.coordinates.coordinates[0],
        otherPost.location.coordinates.coordinates[1],
        otherPost.location.coordinates.coordinates[0]
      );

      if (distance <= clusterRadius) {
        cluster.postsInCluster.push(otherPost);
        const otherEmotionName = (otherPost.emotion && typeof otherPost.emotion.name === 'string') ? otherPost.emotion.name : 'Unknown';
        cluster.emotionNamesInCluster.push(otherEmotionName);
        processed.add(j);
      }
    }

    if (cluster.postsInCluster.length > 1) {
      const avgLat = cluster.postsInCluster.reduce((sum, p) => sum + p.location.coordinates.coordinates[1], 0) / cluster.postsInCluster.length;
      const avgLng = cluster.postsInCluster.reduce((sum, p) => sum + p.location.coordinates.coordinates[0], 0) / cluster.postsInCluster.length;
      
      cluster.location.coordinates.coordinates = [avgLng, avgLat];
      cluster.count = cluster.postsInCluster.length;
      // Use emotionNamesInCluster for getMostFrequent
      cluster.dominantEmotionName = getMostFrequent(cluster.emotionNamesInCluster); 
      // The cluster itself doesn't have a single 'emotion' object in the same way a post does.
      // It might have a representative emotion name. Adjust Swift client if it expects a full SimpleEmotion object for clusters.
      // For now, sending dominantEmotionName. The client will need to handle this.
      // Or, find the full dominant emotion object if needed.
      // For simplicity, let's assume dominantEmotionName is enough or find the first post's emotion object with that name.
      const dominantEmotionObject = cluster.postsInCluster.find(p => (p.emotion && p.emotion.name) === cluster.dominantEmotionName)?.emotion || cluster.postsInCluster[0].emotion;

      clusters.push({
        // Fields expected by a "cluster" representation on the client
        id: `cluster_${avgLng.toFixed(5)}_${avgLat.toFixed(5)}_${cluster.count}`,
        type: 'cluster', // Indicates this is a cluster
        location: cluster.location,
        count: cluster.count,
        // Represent the emotion of the cluster, e.g., by the dominant emotion name or its full object
        emotion: dominantEmotionObject, // Or just { name: cluster.dominantEmotionName }
        // The client might need to know it's a cluster and not a single post to render it differently.
        // Individual posts are not directly in this top-level object for a cluster.
      });
    } else {
      // Single post, not clustered
      clusters.push({
        ...post, // 'post' is already the transformed object with likesCount, commentsCount etc.
        id: post._id.toString(), // Use the actual post _id for the 'id' field
        type: 'single', // Indicates this is a single, unclustered post
        // count: 1, // 'count' might be redundant if it's always 1 for single, but can be explicit
      });
    }
  });
  return clusters;
}

// Helper function to find most frequent element (remains the same)
function getMostFrequent(arr) {
  if (!arr || arr.length === 0) return null;
  const counts = {};
  let maxCount = 0;
  let mostFrequent = arr[0]; // Default to first item

  arr.forEach(item => {
    if (item === null || typeof item === 'undefined') return;
    const key = typeof item === 'object' ? JSON.stringify(item) : item; // Handle objects if emotions are complex
    counts[key] = (counts[key] || 0) + 1;
    if (counts[key] > maxCount) {
      maxCount = counts[key];
      mostFrequent = item;
    }
  });
  return mostFrequent;
}

export default mapRouter;