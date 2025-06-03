import { Router } from 'express';
import MoodPost from '../models/MoodPost.js';

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
  return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
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
      limit = 500, // Higher limit for map display
      privacy = 'public',
      cluster = 'false',
      zoomLevel = 10
    } = req.query;

    // Validate required boundary coordinates
    if (!swLat || !swLng || !neLat || !neLng) {
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
      return res.status(400).json({
        success: false,
        error: 'Invalid coordinates'
      });
    }

    // Build MongoDB query
    const query = {
      // Must have location data
      'location.coordinates': { $exists: true, $ne: null },
      
      // Privacy filter
      $or: [
        { privacy: 'public' },
        // Add user-specific privacy logic here if needed
        // e.g., { privacy: 'friends', userId: { $in: req.user.friends } }
      ]
    };

    // Time-based filtering
    if (since) {
      const sinceDate = new Date(since);
      if (!isNaN(sinceDate.getTime())) {
        query.timestamp = { $gte: sinceDate };
      }
    } else {
      // Default to last 7 days for performance
      const sevenDaysAgo = new Date(Date.now() - 7 * 24 * 60 * 60 * 1000);
      query.timestamp = { $gte: sevenDaysAgo };
    }

    // Geospatial query using MongoDB's $geoWithin
    query['location.coordinates'] = {
      $geoWithin: {
        $box: [
          [bounds.sw.lng, bounds.sw.lat], // Bottom-left [lng, lat]
          [bounds.ne.lng, bounds.ne.lat]  // Top-right [lng, lat]
        ]
      }
    };

    // Fetch mood posts
    let moodPosts = await MoodPost.find(query)
      .sort({ timestamp: -1 })
      .limit(parseInt(limit))
      .select('userId emotion reason location timestamp privacy isAnonymous')
      .populate('userId', 'username profilePicture')
      .lean(); // Use lean() for better performance

    // Calculate distance from center if provided
    if (centerLat && centerLng) {
      const center = {
        lat: parseFloat(centerLat),
        lng: parseFloat(centerLng)
      };
      
      if (isValidCoordinate(center.lat, center.lng)) {
        moodPosts = moodPosts.map(post => ({
          ...post,
          distance: calculateDistance(
            center.lat, center.lng,
            post.location.coordinates.coordinates[1], // lat
            post.location.coordinates.coordinates[0]  // lng
          )
        }));
      }
    }

    // Optional: Cluster nearby posts based on zoom level
    let responseData = moodPosts;
    
    if (cluster === 'true' && parseInt(zoomLevel) < 15) {
      responseData = clusterMoodPosts(moodPosts, parseInt(zoomLevel));
    }

    res.json({
      success: true,
      count: responseData.length,
      viewport: bounds,
      clustered: cluster === 'true',
      data: responseData
    });

  } catch (error) {
    console.error('Error fetching map moods:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch mood posts' 
    });
  }
});

/**
 * GET /api/map/moods/heatmap
 * Get aggregated mood data for heatmap visualization
 */
mapRouter.get('/moods/heatmap', async (req, res) => {
  try {
    const { swLat, swLng, neLat, neLng, gridSize = 50 } = req.query;

    if (!swLat || !swLng || !neLat || !neLng) {
      return res.status(400).json({
        success: false,
        error: 'Boundary coordinates required'
      });
    }

    const bounds = {
      sw: { lat: parseFloat(swLat), lng: parseFloat(swLng) },
      ne: { lat: parseFloat(neLat), lng: parseFloat(neLng) }
    };

    // Aggregate mood posts into grid cells
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
          privacy: 'public',
          timestamp: { $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) }
        }
      },
      {
        $project: {
          lat: { $arrayElemAt: ['$location.coordinates.coordinates', 1] },
          lng: { $arrayElemAt: ['$location.coordinates.coordinates', 0] },
          emotion: 1
        }
      },
      {
        $group: {
          _id: {
            latBucket: {
              $floor: {
                $multiply: [
                  { $divide: [{ $subtract: ['$lat', bounds.sw.lat] }, 
                    { $subtract: [bounds.ne.lat, bounds.sw.lat] }] },
                  parseInt(gridSize)
                ]
              }
            },
            lngBucket: {
              $floor: {
                $multiply: [
                  { $divide: [{ $subtract: ['$lng', bounds.sw.lng] }, 
                    { $subtract: [bounds.ne.lng, bounds.sw.lng] }] },
                  parseInt(gridSize)
                ]
              }
            }
          },
          count: { $sum: 1 },
          emotions: { $push: '$emotion' }
        }
      }
    ]);

    // Convert to heatmap points
    const points = heatmapData.map(cell => {
      const latStep = (bounds.ne.lat - bounds.sw.lat) / parseInt(gridSize);
      const lngStep = (bounds.ne.lng - bounds.sw.lng) / parseInt(gridSize);
      
      return {
        lat: bounds.sw.lat + (cell._id.latBucket + 0.5) * latStep,
        lng: bounds.sw.lng + (cell._id.lngBucket + 0.5) * lngStep,
        intensity: cell.count,
        dominantEmotion: getMostFrequent(cell.emotions)
      };
    });

    res.json({
      success: true,
      gridSize: parseInt(gridSize),
      bounds,
      data: points
    });

  } catch (error) {
    console.error('Error generating heatmap:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to generate heatmap data' 
    });
  }
});

/**
 * GET /api/map/moods/:id
 * Get detailed information about a specific mood post
 */
mapRouter.get('/moods/:id', async (req, res) => {
  try {
    const moodPost = await MoodPost.findById(req.params.id)
      .populate('userId', 'username profilePicture bio')
      .populate('comments.userId', 'username profilePicture');

    if (!moodPost) {
      return res.status(404).json({
        success: false,
        error: 'Mood post not found'
      });
    }

    // Check privacy settings
    // Add your privacy logic here

    res.json({
      success: true,
      data: moodPost
    });

  } catch (error) {
    if (error.name === 'CastError') {
      return res.status(400).json({
        success: false,
        error: 'Invalid mood post ID'
      });
    }
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch mood post' 
    });
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
    const maxDistance = parseFloat(req.query.maxDistance) || 5000; // meters
    const limit = parseInt(req.query.limit) || 50;

    if (!isValidCoordinate(lat, lng)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid coordinates'
      });
    }

    const moodPosts = await MoodPost.aggregate([
      {
        $geoNear: {
          near: {
            type: 'Point',
            coordinates: [lng, lat]
          },
          distanceField: 'distance',
          maxDistance: maxDistance,
          spherical: true,
          query: {
            privacy: 'public',
            timestamp: { $gte: new Date(Date.now() - 7 * 24 * 60 * 60 * 1000) }
          }
        }
      },
      { $limit: limit },
      {
        $lookup: {
          from: 'users',
          localField: 'userId',
          foreignField: '_id',
          as: 'user'
        }
      },
      {
        $unwind: '$user'
      },
      {
        $project: {
          emotion: 1,
          reason: 1,
          location: 1,
          timestamp: 1,
          privacy: 1,
          isAnonymous: 1,
          distance: 1,
          'user.username': 1,
          'user.profilePicture': 1
        }
      }
    ]);

    res.json({
      success: true,
      center: { lat, lng },
      maxDistance,
      count: moodPosts.length,
      data: moodPosts
    });

  } catch (error) {
    console.error('Error fetching nearby moods:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch nearby mood posts' 
    });
  }
});

/**
 * GET /api/map/stats
 * Get statistics about mood posts in an area
 */
mapRouter.get('/stats', async (req, res) => {
  try {
    const { swLat, swLng, neLat, neLng } = req.query;

    if (!swLat || !swLng || !neLat || !neLng) {
      return res.status(400).json({
        success: false,
        error: 'Boundary coordinates required'
      });
    }

    const bounds = {
      sw: { lat: parseFloat(swLat), lng: parseFloat(swLng) },
      ne: { lat: parseFloat(neLat), lng: parseFloat(neLng) }
    };

    const stats = await MoodPost.aggregate([
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
          timestamp: { $gte: new Date(Date.now() - 30 * 24 * 60 * 60 * 1000) }
        }
      },
      {
        $group: {
          _id: null,
          totalPosts: { $sum: 1 },
          emotionCounts: {
            $push: '$emotion'
          },
          averagePerDay: {
            $avg: {
              $dateDiff: {
                startDate: '$timestamp',
                endDate: new Date(),
                unit: 'day'
              }
            }
          }
        }
      },
      {
        $project: {
          totalPosts: 1,
          emotionBreakdown: {
            $arrayToObject: {
              $map: {
                input: { $setUnion: ['$emotionCounts'] },
                as: 'emotion',
                in: {
                  k: '$$emotion',
                  v: {
                    $size: {
                      $filter: {
                        input: '$emotionCounts',
                        cond: { $eq: ['$$this', '$$emotion'] }
                      }
                    }
                  }
                }
              }
            }
          },
          postsPerDay: { $divide: ['$totalPosts', 30] }
        }
      }
    ]);

    res.json({
      success: true,
      bounds,
      data: stats[0] || {
        totalPosts: 0,
        emotionBreakdown: {},
        postsPerDay: 0
      }
    });

  } catch (error) {
    console.error('Error fetching map stats:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch statistics' 
    });
  }
});

// Helper function to cluster mood posts
function clusterMoodPosts(posts, zoomLevel) {
  const clusters = [];
  const processed = new Set();
  
  // Clustering radius based on zoom level (in kilometers)
  const clusterRadius = Math.max(0.5, 20 / Math.pow(2, zoomLevel));
  
  posts.forEach((post, i) => {
    if (processed.has(i)) return;
    
    const cluster = {
      id: `cluster_${i}`,
      type: 'cluster',
      location: post.location,
      posts: [post],
      emotions: [post.emotion]
    };
    
    // Find nearby posts to cluster
    posts.forEach((otherPost, j) => {
      if (i === j || processed.has(j)) return;
      
      const distance = calculateDistance(
        post.location.coordinates.coordinates[1],
        post.location.coordinates.coordinates[0],
        otherPost.location.coordinates.coordinates[1],
        otherPost.location.coordinates.coordinates[0]
      );
      
      if (distance <= clusterRadius) {
        cluster.posts.push(otherPost);
        cluster.emotions.push(otherPost.emotion);
        processed.add(j);
      }
    });
    
    processed.add(i);
    
    if (cluster.posts.length > 1) {
      // Calculate cluster center
      const avgLat = cluster.posts.reduce((sum, p) => 
        sum + p.location.coordinates.coordinates[1], 0) / cluster.posts.length;
      const avgLng = cluster.posts.reduce((sum, p) => 
        sum + p.location.coordinates.coordinates[0], 0) / cluster.posts.length;
      
      cluster.location = {
        coordinates: {
          type: 'Point',
          coordinates: [avgLng, avgLat]
        }
      };
      
      cluster.count = cluster.posts.length;
      cluster.dominantEmotion = getMostFrequent(cluster.emotions);
      delete cluster.posts; // Remove individual posts to reduce payload
      
      clusters.push(cluster);
    } else {
      // Single post, not clustered
      clusters.push({
        ...post,
        type: 'single'
      });
    }
  });
  
  return clusters;
}

// Helper function to find most frequent element
function getMostFrequent(arr) {
  const counts = {};
  let maxCount = 0;
  let mostFrequent = arr[0];
  
  arr.forEach(item => {
    counts[item] = (counts[item] || 0) + 1;
    if (counts[item] > maxCount) {
      maxCount = counts[item];
      mostFrequent = item;
    }
  });
  
  return mostFrequent;
}

// Ensure 2dsphere index exists for geospatial queries
// Add this to your MoodPost model or database setup:
// MoodPost.collection.createIndex({ 'location.coordinates': '2dsphere' });

export default mapRouter;