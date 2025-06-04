import { Router } from 'express';
import { createReport, getReports, reviewReport } from '../controllers/reportController.js';
import requireAuth from '../middleware/requireAuth.js';
import requireAdmin from '../middleware/requireAdmin.js';

const reportRouter = Router(); 
reportRouter.use(requireAuth);

// GET - Retrieve all reports
reportRouter.get('/', requireAdmin, getReports);

// POST - Create a new report
reportRouter.post('/:id', createReport);

// PATCH - review a report
reportRouter.patch('/:id/review', requireAdmin, reviewReport);

export default reportRouter; 