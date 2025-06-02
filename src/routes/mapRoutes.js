// routes/mapRoutes.js
import { Router } from 'express';
import Location from '../models/Location.js';

const mapRouter = Router();

const calculateDistance = (lat1, lng1, lat2, lng2) => {
  const R = 6371; 
  const dLat = (lat2 - lat1) * Math.PI / 180;
  const dLng = (lng2 - lng1) * Math.PI / 180;
  const a = Math.sin(dLat/2) * Math.sin(dLat/2) +
    Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
    Math.sin(dLng/2) * Math.sin(dLng/2);
  const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1-a));
  return R * c;
};

const isValidCoordinate = (lat, lng) => {
  return lat >= -90 && lat <= 90 && lng >= -180 && lng <= 180;
};

mapRouter.get('/locations', async (req, res) => {
  try {
    const { type, radius, lat, lng, limit = 50 } = req.query;
    let query = {};
    
    if (type) {
      query.type = type;
    }
    
    let locations = await Location.find(query).limit(parseInt(limit));
    
    if (radius && lat && lng) {
      const centerLat = parseFloat(lat);
      const centerLng = parseFloat(lng);
      const searchRadius = parseFloat(radius);
      
      if (isValidCoordinate(centerLat, centerLng)) {
        locations = locations.filter(loc => {
          const distance = calculateDistance(centerLat, centerLng, loc.lat, loc.lng);
          return distance <= searchRadius;
        }).map(loc => ({
          ...loc.toObject(),
          distance: calculateDistance(centerLat, centerLng, loc.lat, loc.lng)
        }));
      }
    }
    
    res.json({
      success: true,
      count: locations.length,
      data: locations
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

mapRouter.get('/locations/:id', async (req, res) => {
  try {
    const location = await Location.findById(req.params.id);
    
    if (!location) {
      return res.status(404).json({ 
        success: false, 
        error: 'Location not found' 
      });
    }
    
    res.json({ success: true, data: location });
  } catch (error) {
    if (error.name === 'CastError') {
      return res.status(400).json({ 
        success: false, 
        error: 'Invalid location ID format' 
      });
    }
    res.status(500).json({ success: false, error: error.message });
  }
});

mapRouter.post('/locations', async (req, res) => {
  try {
    const { name, lat, lng, type, description, address } = req.body;
    
    if (!name || lat === undefined || lng === undefined) {
      return res.status(400).json({
        success: false,
        error: 'Name, latitude, and longitude are required'
      });
    }
    
    if (!isValidCoordinate(lat, lng)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid coordinates provided'
      });
    }
    
    const newLocation = new Location({
      name: name.trim(),
      lat: parseFloat(lat),
      lng: parseFloat(lng),
      type: type || 'general',
      description: description?.trim(),
      address: address?.trim()
    });
    
    const savedLocation = await newLocation.save();
    
    res.status(201).json({
      success: true,
      data: savedLocation
    });
  } catch (error) {
    if (error.name === 'ValidationError') {
      return res.status(400).json({
        success: false,
        error: error.message
      });
    }
    res.status(500).json({ success: false, error: error.message });
  }
});

mapRouter.put('/locations/:id', async (req, res) => {
  try {
    const { name, lat, lng, type, description, address } = req.body;
    
    if ((lat !== undefined || lng !== undefined) && 
        !isValidCoordinate(lat, lng)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid coordinates provided'
      });
    }
    
    const updateData = { updatedAt: new Date() };
    if (name !== undefined) updateData.name = name.trim();
    if (lat !== undefined) updateData.lat = parseFloat(lat);
    if (lng !== undefined) updateData.lng = parseFloat(lng);
    if (type !== undefined) updateData.type = type;
    if (description !== undefined) updateData.description = description?.trim();
    if (address !== undefined) updateData.address = address?.trim();
    
    const updatedLocation = await Location.findByIdAndUpdate(
      req.params.id, 
      updateData, 
      { new: true, runValidators: true }
    );
    
    if (!updatedLocation) {
      return res.status(404).json({
        success: false,
        error: 'Location not found'
      });
    }
    
    res.json({
      success: true,
      data: updatedLocation
    });
  } catch (error) {
    if (error.name === 'CastError') {
      return res.status(400).json({ 
        success: false, 
        error: 'Invalid location ID format' 
      });
    }
    if (error.name === 'ValidationError') {
      return res.status(400).json({
        success: false,
        error: error.message
      });
    }
    res.status(500).json({ success: false, error: error.message });
  }
});

mapRouter.delete('/locations/:id', async (req, res) => {
  try {
    const deletedLocation = await Location.findByIdAndDelete(req.params.id);
    
    if (!deletedLocation) {
      return res.status(404).json({
        success: false,
        error: 'Location not found'
      });
    }
    
    res.json({
      success: true,
      message: 'Location deleted successfully',
      data: deletedLocation
    });
  } catch (error) {
    if (error.name === 'CastError') {
      return res.status(400).json({ 
        success: false, 
        error: 'Invalid location ID format' 
      });
    }
    res.status(500).json({ success: false, error: error.message });
  }
});

mapRouter.get('/locations/nearby/:lat/:lng', async (req, res) => {
  try {
    const centerLat = parseFloat(req.params.lat);
    const centerLng = parseFloat(req.params.lng);
    const radius = parseFloat(req.query.radius) || 10; // Default 10km
    const limit = parseInt(req.query.limit) || 50;
    
    if (!isValidCoordinate(centerLat, centerLng)) {
      return res.status(400).json({
        success: false,
        error: 'Invalid coordinates provided'
      });
    }
    
    const allLocations = await Location.find({});
    
    const nearbyLocations = allLocations
      .map(location => ({
        ...location.toObject(),
        distance: calculateDistance(centerLat, centerLng, location.lat, location.lng)
      }))
      .filter(location => location.distance <= radius)
      .sort((a, b) => a.distance - b.distance)
      .slice(0, limit);
    
    res.json({
      success: true,
      center: { lat: centerLat, lng: centerLng },
      radius,
      count: nearbyLocations.length,
      data: nearbyLocations
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

mapRouter.post('/locations/search', async (req, res) => {
  try {
    const { query, type, limit = 10 } = req.body;
    
    if (!query) {
      return res.status(400).json({
        success: false,
        error: 'Search query is required'
      });
    }
    
    const searchCriteria = {
      name: { $regex: query, $options: 'i' }
    };
    
    if (type) {
      searchCriteria.type = type;
    }
    
    const results = await Location.find(searchCriteria).limit(parseInt(limit));
    
    res.json({
      success: true,
      query,
      count: results.length,
      data: results
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

mapRouter.get('/types', async (req, res) => {
  try {
    const typesWithCounts = await Location.aggregate([
      {
        $group: {
          _id: '$type',
          count: { $sum: 1 }
        }
      },
      {
        $project: {
          _id: 0,
          type: '$_id',
          count: 1
        }
      },
      {
        $sort: { type: 1 }
      }
    ]);
    
    res.json({
      success: true,
      data: typesWithCounts
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

mapRouter.get('/bounds', async (req, res) => {
  try {
    const locations = await Location.find({}, 'lat lng');
    
    if (locations.length === 0) {
      return res.json({
        success: true,
        data: null,
        message: 'No locations available'
      });
    }
    
    const lats = locations.map(loc => loc.lat);
    const lngs = locations.map(loc => loc.lng);
    
    const bounds = {
      north: Math.max(...lats),
      south: Math.min(...lats),
      east: Math.max(...lngs),
      west: Math.min(...lngs),
      center: {
        lat: (Math.max(...lats) + Math.min(...lats)) / 2,
        lng: (Math.max(...lngs) + Math.min(...lngs)) / 2
      }
    };
    
    res.json({
      success: true,
      data: bounds
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

mapRouter.post('/routes/calculate', async (req, res) => {
  try {
    const { start, end, waypoints = [] } = req.body;
    
    if (!start || !end || !start.lat || !start.lng || !end.lat || !end.lng) {
      return res.status(400).json({
        success: false,
        error: 'Start and end points with lat/lng are required'
      });
    }
    
    const allPoints = [start, end, ...waypoints];
    for (const point of allPoints) {
      if (!isValidCoordinate(point.lat, point.lng)) {
        return res.status(400).json({
          success: false,
          error: 'Invalid coordinates in route points'
        });
      }
    }
    
    let totalDistance = 0;
    const routePoints = [start, ...waypoints, end];
    
    for (let i = 0; i < routePoints.length - 1; i++) {
      totalDistance += calculateDistance(
        routePoints[i].lat, routePoints[i].lng,
        routePoints[i + 1].lat, routePoints[i + 1].lng
      );
    }
    
    const calculatedRoute = {
      start,
      end,
      waypoints,
      totalDistance: Math.round(totalDistance * 100) / 100,
      estimatedTime: Math.round(totalDistance * 60 / 50), 
      routePoints
    };
    
    res.json({
      success: true,
      data: calculatedRoute
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
});

export default mapRouter;