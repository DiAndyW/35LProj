// models/Location.js
import mongoose from 'mongoose';

const { Schema } = mongoose;

const locationSchema = new Schema({
  name: { 
    type: String, 
    required: true,
    trim: true
  },
  lat: { 
    type: Number, 
    required: true,
    min: -90,
    max: 90
  },
  lng: { 
    type: Number, 
    required: true,
    min: -180,
    max: 180
  },
  type: { 
    type: String, 
    default: 'general',
    enum: ['park', 'landmark', 'restaurant', 'general', 'hospital', 'school', 'library', 'gym', 'cafe']
  },
  description: {
    type: String,
    maxlength: 500
  },
  address: {
    type: String,
    trim: true
  },
  checkInCount: {
    type: Number,
    default: 0
  },
  averageMoodRating: {
    type: Number,
    min: 1,
    max: 5,
    default: null
  }
}, {
  timestamps: true,
  toJSON: { virtuals: true },
  toObject: { virtuals: true }
});

// Create indexes for better query performance
locationSchema.index({ lat: 1, lng: 1 });
locationSchema.index({ type: 1 });
locationSchema.index({ name: 'text' });
locationSchema.index({ checkInCount: -1 });

const Location = mongoose.model('Location', locationSchema);

export default Location;