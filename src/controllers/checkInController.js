import MoodCheckIn from '../models/CheckIn.js';

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

    const userIdValidation = validateObjectId(userId, 'userId');
    if (!userIdValidation.isValid) {
      return res.status(400).json({ error: userIdValidation.error });
    }

    let processedLocationForDb = null;

    if (location) {
      const clientLandmarkName = (location.landmarkName && typeof location.landmarkName === 'string')
        ? location.landmarkName.trim()
        : null;

      if (location.coordinates && typeof location.coordinates === 'object') {
        const clientGeoJsonData = location.coordinates;

        if (clientGeoJsonData.type === 'Point' &&
          Array.isArray(clientGeoJsonData.coordinates) &&
          clientGeoJsonData.coordinates.length === 2 &&
          typeof clientGeoJsonData.coordinates[0] === 'number' &&
          typeof clientGeoJsonData.coordinates[1] === 'number') {

          processedLocationForDb = {
            landmarkName: clientLandmarkName,
            coordinates: {
              type: 'Point',
              coordinates: [clientGeoJsonData.coordinates[0], clientGeoJsonData.coordinates[1]]
            }
          };
        } else {
          return res.status(400).json({
            error: 'Invalid location.coordinates structure. Expected { type: "Point", coordinates: [longitude, latitude] } with numerical longitude and latitude.',
            receivedCoordinatesObject: clientGeoJsonData
          });
        }
      } else if (clientLandmarkName) {
        processedLocationForDb = null;
      } else if (Object.keys(location).length > 0) {
        return res.status(400).json({ error: 'Location object provided but lacks valid landmarkName or coordinates data.' });
      }
    }

    const validPrivacySettings = ['friends', 'public', 'private'];
    const processedPrivacy = privacy && validPrivacySettings.includes(privacy.toLowerCase())
      ? privacy.toLowerCase()
      : 'private';

    if (reason && reason.length > 500) {
      return res.status(400).json({
        error: 'Reason text exceeds maximum length of 500 characters',
        currentLength: reason.length
      });
    }

    const processedPeople = Array.isArray(people)
      ? people.filter(person => typeof person === 'string' && person.trim().length > 0)
      : [];

    const processedActivities = Array.isArray(activities)
      ? activities.filter(activity => typeof activity === 'string' && activity.trim().length > 0)
      : [];

    const newCheckIn = new MoodCheckIn({
      userId,
      emotion: {
        name: emotion.name,
        attributes: emotion.attributes || {}
      },
      reason: reason || null,
      people: processedPeople,
      activities: processedActivities,
      location: processedLocationForDb,
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

// GET - Retrieve a user's check-ins with enhanced filtering and pagination
export const getUserCheckIns = async (req, res) => {
  try {
    const { userId } = req.params;

    // Pagination parameters from query string
    const page = parseInt(req.query.page, 10) || 1; // Default to page 1
    const limit = parseInt(req.query.limit, 10) || 10; // Default to 10 items per page
    const skip = (page - 1) * limit;

    // Validate userId
    const userIdValidation = validateObjectId(userId, 'userId');
    if (!userIdValidation.isValid) {
      return res.status(400).json({ error: userIdValidation.error });
    }

    const checkInsQuery = MoodCheckIn.find({ userId: userId })
      .sort({ timestamp: -1 })
      .skip(skip)
      .limit(limit);

    const checkIns = await checkInsQuery;

    // Optionally, get total count for pagination metadata
    const totalCheckIns = await MoodCheckIn.countDocuments({ userId: userId });

    const responseData = checkIns.map(checkIn => checkIn.displayData);

    res.json({
      data: responseData, // The paginated check-ins
      currentPage: page,
      totalPages: Math.ceil(totalCheckIns / limit),
      totalCount: totalCheckIns
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
    const { userId } = req.body;

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

export const updateLikes = async (req, res) => {
  try {

    const { id } = req.params;
    const { userId } = req.body;

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

    if (checkIn.likes.includes(userId)) {
      checkIn.likes.pop(userId);
      await checkIn.save();
    } else {
      checkIn.likes.push(userId);
      await checkIn.save();
    }

    res.json({
      message: 'Like updated successfully',
      checkInId: id,
      likesCount: checkIn.likes.length,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    console.error('Error adding like:', error);
    res.status(500).json({
      error: 'Failed to add like',
      details: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
}

export const addComment = async (req, res) => {
  try {

    const { id } = req.params;
    const { userId, content } = req.body;

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

    if (!content || content.length > 500) {
      return res.status(400).json({
        error: 'Comment content is required and must not exceed 500 characters',
        currentLength: content ? content.length : 0
      });
    }

    const newComment = {
      userId,
      content,
      timestamp: new Date()
    };

    checkIn.comments.push(newComment);
    await checkIn.save();

    res.json({
      message: 'Comment added successfully',
      checkInId: id,
      comment: newComment,
      commentsCount: checkIn.comments.length,
      timestamp: new Date().toISOString()
    });

  } catch (error) {
    console.error('Error adding like:', error);
    res.status(500).json({
      error: 'Failed to add like',
      details: process.env.NODE_ENV === 'development' ? error.message : 'Internal server error'
    });
  }
}