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
    name: {
      type: String,
      default: null
    },
    coordinates: {
      type: [Number], // Array of exactly 2 numbers [longitude, latitude]
      validate: {
        validator: function (v) {
          return v == null || v.length === 2;
        },
        message: 'Coordinates must be an array of exactly 2 numbers'
      },
      default: null
    },
    isShared: {
      type: Boolean,
      default: false
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
    location: this.location.name ? {
      name: this.location.name,
      coordinates: this.location.coordinates,
      isShared: this.location.isShared
    } : null,
    timestamp: this.timestamp,
    isAnonymous: this.isAnonymous, // Uses the virtual property we defined above
    createdAt: this.createdAt,
    updatedAt: this.updatedAt, 
    likes: this.likes,
  };
});

// Database indexes for faster queries
moodCheckInSchema.index({ userId: 1, timestamp: -1 }); // Find user's check-ins by date
moodCheckInSchema.index({ privacy: 1 }); // Filter by privacy level
moodCheckInSchema.index({ 'location.coordinates': '2dsphere' }); // Geographic queries

const MoodCheckIn = mongoose.model('MoodCheckIn', moodCheckInSchema);

export default MoodCheckIn;