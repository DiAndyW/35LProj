import mongoose from 'mongoose';

const { Schema } = mongoose;

// Define the schema structure - think of this as the blueprint for your data
const moodCheckInSchema = new Schema({
  // Who created this check-in (required field)
  userId: {
    type: Schema.Types.ObjectId,
    ref: 'User',
    required: true,
  },

  // The emotion they're feeling (required field)
  emotion: {
    name: {
      type: String,
      required: true,
    },
    // Optional emotional attributes - these store as a flexible object
    attributes: {
      type: Object,
      default: {}
    }
  },

  // Optional explanation of why they feel this way
  reason: {
    type: String,
    maxlength: 500,
  },

  // People they were with (optional array)
  people: [{
    type: String
  }],

  // Activities they were doing (optional array)
  activities: [{
    type: String
  }],

  // Location information (optional)
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

  // Who can see this check-in
  privacy: {
    type: String,
    enum: ['friends', 'public', 'private'], // Only these three values allowed
    default: 'private',
  },

  // When this check-in was created
  timestamp: {
    type: Date,
    default: Date.now, // Automatically set to current time
  }
}, {
  // Schema options - these control how the schema behaves
  timestamps: true, // Automatically add createdAt and updatedAt fields
  toJSON: { virtuals: true }, // Include virtual fields when converting to JSON
  toObject: { virtuals: true } // Include virtual fields when converting to plain object
});

// Virtual property - computed field that doesn't exist in the database
// This calculates whether the check-in is anonymous based on privacy setting
moodCheckInSchema.virtual('isAnonymous').get(function () {
  return this.privacy === 'private';
});

// Virtual property that formats data for frontend consumption
// This creates a clean, consistent format for your API responses
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
    updatedAt: this.updatedAt
  };
});

// Database indexes for faster queries
// Think of these like bookmarks that help MongoDB find data quickly
moodCheckInSchema.index({ userId: 1, timestamp: -1 }); // Find user's check-ins by date
moodCheckInSchema.index({ privacy: 1 }); // Filter by privacy level
moodCheckInSchema.index({ 'location.coordinates': '2dsphere' }); // Geographic queries

// Create the model from the schema
// This is like creating a factory that can make check-in objects
const MoodCheckIn = mongoose.model('MoodCheckIn', moodCheckInSchema);

export default MoodCheckIn;