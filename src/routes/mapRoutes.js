import { Router } from 'express';
import MoodPost from '../models/MoodPost.js'; // Ensure this path is correct

const mapRouter = Router();

// Helper function to calculate distance between two points
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

// Validate coordinates
const isValidCoordinate = (lat, lng) => {
  const numLat = parseFloat(lat);
  const numLng = parseFloat(lng);
  return !isNaN(numLat) && numLat >= -90 && numLat <= 90 &&
         !isNaN(numLng) && numLng >= -180 && numLng <= 180;
};

/**
 * GET /api/map/moods
 * Fetch mood posts within map viewport bounds
 * Query params:
 * - swLat, swLng: Southwest corner of viewport
 * - neLat, neLng: Northeast corner of viewport
 * - centerLat, centerLng: Center of current view (for distance calculation)
 * - since: ISO timestamp for time filtering
 * - limit: Max number of posts to return
 * - privacy: Filter by privacy level (public/friends/private)
 * - cluster: Whether to cluster nearby posts (true/false)
 * - zoomLevel: Current zoom level for clustering decisions
 */
mapRouter.get('/moods', async (req, res) => {
  try {
    const {
      swLat, swLng, neLat, neLng,
      centerLat, centerLng,
      since,
      limit = '500', // Default as string, will be parsed
      privacy = 'public',
      cluster = 'false',
      zoomLevel = '10' // Default as string, will be parsed
    } = req.query;

    // --- DEBUGGING: Log incoming query parameters ---
    console.log('Received /moods request with query params:', req.query);

    // Validate required boundary coordinates
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
    
    // --- DEBUGGING: Log parsed bounds ---
    console.log('Parsed map bounds:', bounds);

    // Build MongoDB query
    const queryConditions = {
      // Privacy filter first (simpler condition)
      $or: [
        { privacy: 'public' },
        // Add user-specific privacy logic here if needed
      ]
    };

    // IMPORTANT: For $geoWithin with $box, MongoDB expects:
    // - A 2dsphere index on the location.coordinates field
    // - The box defined as [[minLng, minLat], [maxLng, maxLat]]
    // 
    // Since SW/NE might not always have min/max values (depending on hemisphere),
    // we need to ensure we're using the actual min/max values:
    const minLat = Math.min(bounds.sw.lat, bounds.ne.lat);
    const maxLat = Math.max(bounds.sw.lat, bounds.ne.lat);
    const minLng = Math.min(bounds.sw.lng, bounds.ne.lng);
    const maxLng = Math.max(bounds.sw.lng, bounds.ne.lng);

    // Add geospatial query
    queryConditions['location.coordinates'] = {
      $geoWithin: {
        $box: [
          [minLng, minLat], // Bottom-left corner [lng, lat]
          [maxLng, maxLat]  // Top-right corner [lng, lat]
        ]
      }
    };

    // Time-based filtering
    if (since) {
      const sinceDate = new Date(since);
      if (!isNaN(sinceDate.getTime())) {
        queryConditions.timestamp = { $gte: sinceDate };
        console.log('Using provided since date:', sinceDate);
      } else {
        console.warn('Invalid "since" date format received:', since);
      }
    } else {
      // Default to last 7 days for performance
      const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
      queryConditions.timestamp = { $gte: sevenDaysAgo };
      console.log('Using default 7-day filter:', sevenDaysAgo);
    }

    const parsedLimit = parseInt(limit);
    const finalLimit = isNaN(parsedLimit) || parsedLimit <= 0 ? 500 : parsedLimit;

    // --- DEBUGGING: Log the final MongoDB query ---
    console.log('Executing MoodPost.find() with query:', JSON.stringify(queryConditions, null, 2));
    console.log('Box coordinates: minLng:', minLng, 'minLat:', minLat, 'maxLng:', maxLng, 'maxLat:', maxLat);

    // First, let's check if we have ANY public posts in the database
    const totalPublicPosts = await MoodPost.countDocuments({ privacy: 'public' });
    console.log('Total public posts in database:', totalPublicPosts);

    // Check posts within the time range
    const postsInTimeRange = await MoodPost.countDocuments({ 
      privacy: 'public',
      timestamp: queryConditions.timestamp 
    });
    console.log('Public posts within time range:', postsInTimeRange);

    // Fetch mood posts
    let moodPosts = await MoodPost.find(queryConditions)
      .sort({ timestamp: -1 })
      .limit(finalLimit)
      .select('userId emotion reason location timestamp privacy isAnonymous')
      .populate('userId', 'username profilePicture')
      .lean();

    // --- DEBUGGING: Log fetched posts count ---
    console.log(`Found ${moodPosts.length} mood posts within bounds.`);

    // If no posts found, let's do a diagnostic query
    if (moodPosts.length === 0) {
      // Try to find ANY post with location data
      const anyLocationPost = await MoodPost.findOne({ 
        'location.coordinates': { $exists: true },
        privacy: 'public'
      }).select('location').lean();
      
      if (anyLocationPost) {
        console.log('Sample post with location:', JSON.stringify(anyLocationPost, null, 2));
        console.log('Your query box:', { minLng, minLat, maxLng, maxLat });
        console.log('Check if this location falls within your bounds.');
      } else {
        console.log('No public posts with location data found in the database.');
      }
    }

    // Calculate distance from center if provided
    if (centerLat && centerLng) {
      const center = {
        lat: parseFloat(centerLat),
        lng: parseFloat(centerLng)
      };

      if (isValidCoordinate(center.lat, center.lng)) {
        moodPosts = moodPosts.map(post => {
          if (post.location && post.location.coordinates && post.location.coordinates.coordinates) {
            return {
              ...post,
              distance: calculateDistance(
                center.lat, center.lng,
                post.location.coordinates.coordinates[1], // lat
                post.location.coordinates.coordinates[0]  // lng
              )
            };
          }
          return post;
        });
      } else {
        console.warn('Invalid centerLat/centerLng for distance calculation:', centerLat, centerLng);
      }
    }

    // Optional: Cluster nearby posts based on zoom level
    let responseData = moodPosts;
    const parsedZoomLevel = parseInt(zoomLevel);

    if (cluster === 'true' && !isNaN(parsedZoomLevel) && parsedZoomLevel < 15) {
      responseData = clusterMoodPosts(moodPosts, parsedZoomLevel);
    } else if (cluster === 'true' && (isNaN(parsedZoomLevel) || parsedZoomLevel >= 15)) {
      console.warn(`Clustering requested but zoomLevel ("${zoomLevel}") is invalid or too high for clustering. Serving unclustered data.`);
    }

    res.json({
      success: true,
      count: responseData.length,
      viewport: bounds,
      actualBounds: { minLat, minLng, maxLat, maxLng }, // Add this for debugging
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

// Helper function to cluster mood posts
function clusterMoodPosts(posts, zoomLevel) {
  // Ensure posts have the necessary location structure before clustering
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

  // Clustering radius based on zoom level (in kilometers)
  const baseRadius = 50; // km at zoom level 0
  const clusterRadius = Math.max(0.1, baseRadius / Math.pow(2, zoomLevel));

  validPosts.forEach((post, i) => {
    if (processed.has(i)) return;

    const cluster = {
      type: 'cluster',
      location: JSON.parse(JSON.stringify(post.location)),
      postsInCluster: [post],
      emotions: [post.emotion]
    };

    processed.add(i);

    // Find nearby posts to cluster
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
        cluster.postsInCluster.push(otherPost);
        cluster.emotions.push(otherPost.emotion);
        processed.add(j);
      }
    }

    if (cluster.postsInCluster.length > 1) {
      // Calculate cluster center (average lat/lng)
      const avgLat = cluster.postsInCluster.reduce((sum, p) =>
        sum + p.location.coordinates.coordinates[1], 0) / cluster.postsInCluster.length;
      const avgLng = cluster.postsInCluster.reduce((sum, p) =>
        sum + p.location.coordinates.coordinates[0], 0) / cluster.postsInCluster.length;

      cluster.location.coordinates.coordinates = [avgLng, avgLat];
      cluster.count = cluster.postsInCluster.length;
      cluster.dominantEmotion = getMostFrequent(cluster.emotions);
      cluster.id = `cluster_${avgLng.toFixed(5)}_${avgLat.toFixed(5)}_${cluster.count}`;
      delete cluster.postsInCluster;

      clusters.push(cluster);
    } else {
      // Single post, not clustered
      clusters.push({
        ...post,
        id: `single_${post._id || i}`,
        type: 'single',
        count: 1
      });
    }
  });
  return clusters;
}

// Helper function to find most frequent element
function getMostFrequent(arr) {
  if (!arr || arr.length === 0) return null;

  const counts = {};
  let maxCount = 0;
  let mostFrequent = arr[0];

  arr.forEach(item => {
    if (item === null || typeof item === 'undefined') return;
    counts[item] = (counts[item] || 0) + 1;
    if (counts[item] > maxCount) {
      maxCount = counts[item];
      mostFrequent = item;
    }
  });
  return mostFrequent;
}

export default mapRouter;