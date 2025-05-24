import MoodCheckIn from '../models/CheckIn.js'; // Adjust path if your models directory is elsewhere

// Helper function for common validation logic
const validateObjectId = (id, fieldName) => {
  if (!id || !id.match(/^[0-9a-fA-F]{24}$/)) {
    return { isValid: false, error: `Invalid ${fieldName} format. Must be a valid MongoDB ObjectId` };
  }
  return { isValid: true };
};

// Helper for processing location data
const processLocationData = (location) => {
  let processedLocation = { name: null, coordinates: null, isShared: false };

  if (location) {
    if (typeof location === 'string') {
      processedLocation.name = location;
      processedLocation.isShared = true;
    } else if (typeof location === 'object') {
      processedLocation = {
        name: location.name || null,
        coordinates: location.coordinates || null,
        isShared: location.isShared !== undefined ? location.isShared : false
      };

      if (processedLocation.coordinates &&
        (!Array.isArray(processedLocation.coordinates) ||
          processedLocation.coordinates.length !== 2 ||
          !processedLocation.coordinates.every(coord => typeof coord === 'number'))) {
        return { error: 'Invalid coordinates format. Must be an array of exactly 2 numbers [longitude, latitude]' };
      }
    }
  }
  return { data: processedLocation };
};

// POST - Create a new check-in
export const createCheckIn = async (req, res) => {
  try {
    const {
      userId,
      emotion,
      reason,
      people,
      activities,
      location,
      privacy
    } = req.body;

    // Validate required fields
    if (!userId || !emotion || !emotion.name) {
      return res.status(400).json({
        error: 'Required fields missing: userId and emotion.name are required',
        received: {
          userId: !!userId,
          emotion: !!emotion,
          emotionName: emotion ? !!emotion.name : false
        }
      });
    }

    // Validate userId format
    const userIdValidation = validateObjectId(userId, 'userId');
    if (!userIdValidation.isValid) {
      return res.status(400).json({ error: userIdValidation.error });
    }

    // Process location data
    const locationResult = processLocationData(location);
    if (locationResult.error) {
      return res.status(400).json({ error: locationResult.error });
    }
    const processedLocation = locationResult.data;

    // Validate privacy setting
    const validPrivacySettings = ['friends', 'public', 'private'];
    const processedPrivacy = privacy && validPrivacySettings.includes(privacy.toLowerCase())
      ? privacy.toLowerCase()
      : 'private';

    // Validate reason length
    if (reason && reason.length > 500) {
      return res.status(400).json({
        error: 'Reason text exceeds maximum length of 500 characters',
        currentLength: reason.length
      });
    }

    // Process people array
    const processedPeople = Array.isArray(people)
      ? people.filter(person => typeof person === 'string' && person.trim().length > 0)
      : [];

    // Process activities array
    const processedActivities = Array.isArray(activities)
      ? activities.filter(activity => typeof activity === 'string' && activity.trim().length > 0)
      : [];

    // Create the new check-in with processed data
    const newCheckIn = new MoodCheckIn({
      userId,
      emotion: {
        name: emotion.name.toLowerCase(),
        attributes: emotion.attributes || {}
      },
      reason: reason || null,
      people: processedPeople,
      activities: processedActivities,
      location: processedLocation,
      privacy: processedPrivacy,
      timestamp: new Date()
    });

    const savedCheckIn = await newCheckIn.save();

    res.status(201).json({
      ...savedCheckIn.displayData,
      message: 'Check-in created successfully'
    });

  } catch (error) {
    if (error.name === 'ValidationError') {
      const validationErrors = Object.values(error.errors).map(err => err.message);
      return res.status(400).json({
        error: 'Validation failed',
        details: validationErrors
      });
    }
    console.error('Check-in creation error:', error);
    res.status(500).json({
      error: 'Failed to create check-in',
      details: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// GET - Retrieve a user's check-ins with enhanced filtering
export const getUserCheckIns = async (req, res) => {
  try {
    const { userId } = req.params;
    const {
      limit = 10,
      skip = 0,
      privacy,
      emotion,
      startDate,
      endDate,
      includeLocation = false
    } = req.query;

    const userIdValidation = validateObjectId(userId, 'userId');
    if (!userIdValidation.isValid) {
      return res.status(400).json({ error: userIdValidation.error });
    }

    const parsedLimit = Math.min(Math.max(parseInt(limit, 10) || 10, 1), 100);
    const parsedSkip = Math.max(parseInt(skip, 10) || 0, 0);

    const query = { userId };

    if (privacy && ['friends', 'public', 'private'].includes(privacy.toLowerCase())) {
      query.privacy = privacy.toLowerCase();
    }

    if (emotion) {
      query['emotion.name'] = emotion.toLowerCase();
    }

    if (startDate || endDate) {
      query.timestamp = {};
      if (startDate) {
        const start = new Date(startDate);
        if (!isNaN(start.getTime())) {
          query.timestamp.$gte = start;
        }
      }
      if (endDate) {
        const end = new Date(endDate);
        if (!isNaN(end.getTime())) {
          query.timestamp.$lte = end;
        }
      }
    }

    const checkIns = await MoodCheckIn.find(query)
      .sort({ timestamp: -1 })
      .skip(parsedSkip)
      .limit(parsedLimit);

    const processedCheckIns = checkIns.map(checkIn => {
      const data = checkIn.displayData;
      if (!includeLocation || !checkIn.location.isShared) {
        data.location = null;
      }
      return data;
    });

    res.json({
      checkIns: processedCheckIns,
      pagination: {
        limit: parsedLimit,
        skip: parsedSkip,
        total: processedCheckIns.length,
        hasMore: processedCheckIns.length === parsedLimit
      }
    });

  } catch (error) {
    console.error('Check-in retrieval error:', error);
    res.status(500).json({
      error: 'Failed to retrieve check-ins',
      details: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// GET - Retrieve a specific check-in by ID with privacy considerations
export const getCheckInDetail = async (req, res) => {
  try {
    const { id } = req.params;
    const { requestingUserId } = req.query;

    const idValidation = validateObjectId(id, 'check-in ID');
    if (!idValidation.isValid) {
      return res.status(400).json({ error: idValidation.error });
    }

    const checkIn = await MoodCheckIn.findById(id);

    if (!checkIn) {
      return res.status(404).json({ error: 'Check-in not found' });
    }

    const canView = checkIn.privacy === 'public' ||
      (requestingUserId && checkIn.userId.toString() === requestingUserId);

    if (!canView && checkIn.privacy === 'private') {
      return res.status(403).json({
        error: 'Access denied. This check-in is private.'
      });
    }

    const responseData = checkIn.displayData;

    if (requestingUserId !== checkIn.userId.toString() && !checkIn.location.isShared) {
      responseData.location = null;
    }

    res.json(responseData);

  } catch (error) {
    console.error('Check-in detail retrieval error:', error);
    res.status(500).json({
      error: 'Failed to retrieve check-in details',
      details: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// PUT - Update an existing check-in
export const updateCheckIn = async (req, res) => {
  try {
    const { id } = req.params;
    const { userId, ...updateData } = req.body;

    const idValidation = validateObjectId(id, 'check-in ID');
    if (!idValidation.isValid) {
      return res.status(400).json({ error: idValidation.error });
    }

    const userIdValidation = validateObjectId(userId, 'userId');
    if (!userIdValidation.isValid) {
      return res.status(400).json({ error: userIdValidation.error });
    }

    const checkIn = await MoodCheckIn.findById(id);

    if (!checkIn) {
      return res.status(404).json({ error: 'Check-in not found' });
    }

    if (checkIn.userId.toString() !== userId) {
      return res.status(403).json({ error: 'Unauthorized to modify this check-in' });
    }

    const allowedUpdates = ['emotion', 'reason', 'people', 'activities', 'location', 'privacy'];
    const updates = {};

    Object.keys(updateData).forEach(key => {
      if (allowedUpdates.includes(key)) {
        updates[key] = updateData[key];
      }
    });

    if (updates.reason && updates.reason.length > 500) {
      return res.status(400).json({
        error: 'Reason text exceeds maximum length of 500 characters'
      });
    }

    if (updates.privacy && !['friends', 'public', 'private'].includes(updates.privacy)) {
      return res.status(400).json({ error: 'Invalid privacy setting' });
    }

    // Re-process location if it's being updated
    if (updates.location) {
      const locationResult = processLocationData(updates.location);
      if (locationResult.error) {
        return res.status(400).json({ error: locationResult.error });
      }
      updates.location = locationResult.data;
    }

    const updatedCheckIn = await MoodCheckIn.findByIdAndUpdate(
      id,
      updates,
      { new: true, runValidators: true }
    );

    res.json({
      ...updatedCheckIn.displayData,
      message: 'Check-in updated successfully'
    });

  } catch (error) {
    if (error.name === 'ValidationError') {
      const validationErrors = Object.values(error.errors).map(err => err.message);
      return res.status(400).json({
        error: 'Validation failed',
        details: validationErrors
      });
    }
    console.error('Check-in update error:', error);
    res.status(500).json({
      error: 'Failed to update check-in',
      details: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};

// DELETE - Remove a check-in with proper authorization
export const deleteCheckIn = async (req, res) => {
  try {
    const { id } = req.params;
    const { userId } = req.body; // Assuming userId is sent in body for authorization

    const idValidation = validateObjectId(id, 'check-in ID');
    if (!idValidation.isValid) {
      return res.status(400).json({ error: idValidation.error });
    }

    const userIdValidation = validateObjectId(userId, 'userId');
    if (!userIdValidation.isValid) {
      return res.status(400).json({ error: userIdValidation.error });
    }

    const checkIn = await MoodCheckIn.findById(id);

    if (!checkIn) {
      return res.status(404).json({ error: 'Check-in not found' });
    }

    if (checkIn.userId.toString() !== userId) {
      return res.status(403).json({ error: 'Unauthorized to delete this check-in' });
    }

    await MoodCheckIn.findByIdAndDelete(id);

    res.json({
      message: 'Check-in deleted successfully',
      deletedId: id,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Check-in deletion error:', error);
    res.status(500).json({
      error: 'Failed to delete check-in',
      details: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
};
