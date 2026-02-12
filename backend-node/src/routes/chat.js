const express = require('express');
const {
    createSession,
    getSessions,
    streamMessage,
    getSession,
    deleteSession,
    generateTitle,
    createMessage,
} = require('../controllers/chatController');
const { protect } = require('../middleware/auth');

const router = express.Router();

// All chat routes are protected
router.use(protect);

router.route('/sessions').post(createSession).get(getSessions);
router.route('/sessions/:id').get(getSession).delete(deleteSession);
router.post('/sessions/:id/messages', createMessage);
router.post('/sessions/:id/messages/stream', streamMessage);
router.post('/sessions/:id/title', generateTitle);

module.exports = router;
