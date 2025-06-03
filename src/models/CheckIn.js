import mongoose from 'mongoose';

const { Schema } = mongoose;

const moodCheckInSchema = new Schema({
  userId: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },

  emotion: {
    name: {
      type: String,
      required: true,
    },
    attributes: {
      type: Object,
      default: {}
    }
  },

  reason: {
    type: String,
    maxlength: 500,
  },

  people: [{
    type: String
  }],

  activities: [{
    type: String
  }],

  location: {
    landmarkName: { // New field for the landmark
      type: String,
      trim: true,
      default: null
    },
    coordinates: { // Storing as GeoJSON Point
      type: {
        type: String,
        enum: ['Point'], //  Only 'Point' type for now
        // `required` depends on whether coordinates are always mandatory when location is shared
        // Making it not strictly required at schema level to allow landmarkName only, if desired
        // but your controller logic will enforce it if 'location' object is present.
        default: undefined
      },
      coordinates: { // Array of [longitude, latitude]
        type: [Number], // [longitude, latitude]
        default: undefined
      }
    }
  },

  privacy: {
    type: String,
    enum: ['friends', 'public', 'private'], // Only these three values allowed
    default: 'private',
  },

  timestamp: {
    type: Date,
    default: Date.now, // Automatically set to current time
  }, 

  likes: { 
    type: [Schema.Types.ObjectId],
    default: [], 
  }, 

  comments: {
    type: [{
      userId: {
        type: Schema.Types.ObjectId,
        ref: 'User',
        required: true
      },
      content: {
        type: String,
        required: true,
        maxlength: 500
      },
      timestamp: {
        type: Date,
        default: Date.now
      }
    }], 
    default: []
  }
}, {
  timestamps: true, // Automatically add createdAt and updatedAt fields
  toJSON: { virtuals: true }, // Include virtual fields when converting to JSON
  toObject: { virtuals: true } // Include virtual fields when converting to plain object
});

moodCheckInSchema.virtual('isAnonymous').get(function () {
  return this.privacy === 'private';
});

moodCheckInSchema.virtual('displayData').get(function () {
  return {
    _id: this._id,
    userId: this.userId,
    emotion: {
      name: this.emotion.name,
      attributes: this.emotion.attributes
    },
    reason: this.reason,
    people: this.people,
    activities: this.activities,
    privacy: this.privacy,
    location: this.location?.landmarkName ? { // Use landmarkName
      name: this.location.landmarkName, // Changed from this.location.name
      coordinates: this.location.coordinates?.coordinates, // Access nested array
      isShared: this.location.isShared
    } : null,
    timestamp: this.timestamp,
    isAnonymous: this.isAnonymous, // Uses the virtual property we defined above
    createdAt: this.createdAt,
    updatedAt: this.updatedAt, 
    likes: {
      count: this.likes.length,
      userIds: this.likes
    },
    comments: {
      count: this.comments.length,
      data: this.comments.map(comment => ({
        userId: comment.userId,
        content: comment.content,
        timestamp: comment.timestamp
      }))
    }
  };
});

// Database indexes for faster queries
moodCheckInSchema.index({ userId: 1, timestamp: -1 }); // Find user's check-ins by date
moodCheckInSchema.index({ privacy: 1 }); // Filter by privacy level
moodCheckInSchema.index({ 'location.coordinates': '2dsphere' }); // Geographic queries
moodCheckInSchema.index({ 'likes.count': -1 }); // Sort by likes count

const MoodCheckIn = mongoose.model('MoodCheckIn', moodCheckInSchema);

export default MoodCheckIn;