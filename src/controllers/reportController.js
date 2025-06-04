import mongoose from 'mongoose';
import Report from '../models/reportModel.js';
import CheckIn from '../models/CheckIn.js';
import User from '../models/UserModel.js';

// GET - Retrieve all reports
export const getReports = async (req, res) => {
    try {
        const reports = await Report.find().sort({ status: 1, createdAt: -1 });
        
        // For each report, fetch the referenced object
        const reportsWithObjects = await Promise.all(reports.map(async (report) => {
            let reportedObject = null;
            if (report.objectType === 'user') {
                reportedObject = await User.findById(report.objectId).select('_id username email');
            } else if (report.objectType === 'checkin') {
                reportedObject = await CheckIn.findById(report.objectId);
                if (reportedObject) {
                    reportedObject = reportedObject.displayData; // Use displayData for check-ins
                }
            } else {
                return res.status(400).json({ message: 'Invalid object type in report.' });
            }
            return {
                ...report.toObject(),
                reportedObject
            };
        }));
        
        res.json(reportsWithObjects);
    } catch (error) {
        console.error('Error fetching reports:', error);
        res.status(500).json({ message: 'Failed to fetch reports', details: error.message });
    }
}

// POST - Create a new report
export const createReport = async (req, res) => {
    const objectId = req.params.id;
    const { objectType, reason} = req.body;
    const reportedBy = req.user.sub;

    // validate object ID
    if (!mongoose.Types.ObjectId.isValid(objectId)) {
        return res.status(400).json({ message: 'Invalid object ID.' });
    }
    // validate object type and reason
    if (!objectType || !reason) {
        return res.status(400).json({ message: 'Object type and reason are required.' });
    }
    // prevent self-reporting
    if (objectType === 'user' && objectId === reportedBy) {
    return res.status(400).json({ message: 'You cannot report yourself.' });
    }
    // validate reason length
    if (reason.length < 10 || reason.length > 500) {
        return res.status(400).json({ message: 'Reason must be between 10 and 500 characters.' });
    }
    // validate object type
    const validObjectTypes = Report.schema.path('objectType').enumValues;
    if (!validObjectTypes.includes(objectType)) {
        return res.status(400).json({ message: 'Invalid object type. Must be checkin, comment, or user.' });
    }
    if (objectType === 'checkin') {
        const checkin = await CheckIn.findById(objectId);
        if (!checkin) {
            return res.status(404).json({ message: 'Check-in not found.' });
        }
    } else if (objectType === 'user') {
        const user = await User.findById(objectId);
        if (!user) {
            return res.status(404).json({ message: 'User not found.' });
        }
    }

    try {
        const report = new Report({
            objectId, 
            objectType, 
            reportedBy,
            reason
        });

        res.status(201).json({ message: 'Report created successfully' });

        await report.save(); 

        return res.json({ message: 'report is valid' });
    } catch (error) {
        console.error('Error creating report:', error);
        return res.status(500).json({ message: 'Failed to create report', details: error.message });
    }
}

// PATCH - Update a report status
export const reviewReport = async (req, res) => {  
    const { id } = req.params;

    // validate report ID 
    if (!mongoose.Types.ObjectId.isValid(id)) {
        return res.status(400).json({ message: 'Invalid report ID.' });
    }
    // validate status
    const report = await Report.findById(id).select('status objectType reason');
    if (!report) {
        return res.status(404).json({ message: 'Report not found.'
         });
    }
    if (report.status !== 'pending') {
        return res.status(400).json({ message: 'Report has already been reviewed',
            report: {
                status: report.status,
                objectType: report.objectType,
                reason: report.reason
            }
         });
    }

    try {
        const updatedReport = await Report.findByIdAndUpdate(id, { status: 'reviewed' }, { new: true });
        if (!updatedReport) {
            return res.status(404).json({ message: 'Report not found.' });
        }
        res.json({ 
            message: 'Report updated successfully', 
            status: updatedReport.status,
            objectType: updatedReport.objectType,
            reason: updatedReport.reason
         });
    } catch (error) {
        console.error('Error updating report:', error);
        res.status(500).json({ message: 'Failed to update report', details: error.message });
    }
}