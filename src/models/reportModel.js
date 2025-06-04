import mongoose from 'mongoose';

const reportSchema = new mongoose.Schema({
    objectId: { 
        type: mongoose.Schema.Types.ObjectId, 
    },
    objectType: { 
        type: String, 
        required: true, 
        enum: ['checkin', 'user'] 
    },
    reportedBy: { 
        type: mongoose.Schema.Types.ObjectId, 
        required: true },
    reason: { 
        type: String, 
        required: true 
    },
    createdAt: {
        type: Date, 
        default: Date.now 
    },
    status: { 
        type: String, 
        default: 'pending', 
        enum: ['pending', 'reviewed']
    }
})

reportSchema.index({ objectId: 1, objectType: 1, createdAt: -1 });

export default mongoose.model('Report', reportSchema, 'reports');