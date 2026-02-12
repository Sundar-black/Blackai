const express = require('express');
const { signup, login, forgotPassword, verifyOtp, resetPassword, checkEmail, updateDetails, deleteMe } = require('../controllers/authController');
const { protect } = require('../middleware/auth');

const router = express.Router();

router.post('/signup', signup);
router.post('/login', login);
router.post('/check-email', checkEmail);
router.post('/forgot-password', forgotPassword);
router.post('/verify-otp', verifyOtp);
router.put('/reset-password', resetPassword);

// Protected self-service routes
router.put('/updatedetails', protect, updateDetails);
router.delete('/deleteme', protect, deleteMe);

module.exports = router;
