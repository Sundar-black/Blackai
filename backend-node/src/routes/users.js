const express = require('express');
const {
    getUsers,
    createUser,
    blockUser,
    deleteUser,
} = require('../controllers/userController');

const { protect } = require('../middleware/auth');
const { authorize } = require('../middleware/admin');

const router = express.Router();

// Apply protection to all routes in this file
router.use(protect);
router.use(authorize('admin'));

router.route('/')
    .get(getUsers)
    .post(createUser);

router.route('/:id')
    .delete(deleteUser);

router.put('/:id/block', blockUser);

module.exports = router;
