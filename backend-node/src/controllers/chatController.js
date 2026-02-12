const Session = require('../models/Session');
const aiService = require('../services/aiService');

// @desc    Create new chat session
// @route   POST /api/chat/sessions
// @access  Private
exports.createSession = async (req, res) => {
    try {
        const session = await Session.create({
            userId: req.user.id,
            title: req.body.title || 'New Chat',
        });

        res.status(201).json({
            success: true,
            data: session,
        });
    } catch (err) {
        res.status(400).json({ success: false, message: err.message });
    }
};

// @desc    Get all chat sessions for user
// @route   GET /api/chat/sessions
// @access  Private
exports.getSessions = async (req, res) => {
    try {
        const sessions = await Session.find({ userId: req.user.id }).sort({ updatedAt: -1 });
        res.status(200).json({ success: true, count: sessions.length, data: sessions });
    } catch (err) {
        res.status(400).json({ success: false, message: err.message });
    }
};

// @desc    Stream chat response
// @route   POST /api/chat/sessions/:id/messages/stream
// @access  Private
exports.streamMessage = async (req, res) => {
    try {
        const session = await Session.findById(req.params.id);

        if (!session) {
            return res.status(404).json({ success: false, message: 'Session not found' });
        }

        if (session.userId.toString() !== req.user.id.toString()) {
            return res.status(401).json({ success: false, message: 'Not authorized' });
        }

        const { role, content, language, tone, length, temperature } = req.body;

        // Add user message to mongo
        session.messages.push({ role, content });
        await session.save();

        // Prepare prompt (last 10 messages for context)
        const history = session.messages.slice(-10).map(m => ({
            role: m.role,
            content: m.content
        }));

        // System prompt with customization
        const systemPrompt = `You are Black, a helpful AI assistant. 
Response Requirements:
- Language: ${language || 'English'}
- Tone: ${tone || 'Friendly'}
- Detail Level: ${length || 'Detailed'}`;

        history.unshift({ role: 'system', content: systemPrompt });

        // Set headers for streaming
        res.setHeader('Content-Type', 'text/plain');
        res.setHeader('Transfer-Encoding', 'chunked');

        let fullResponse = '';

        for await (const chunk of aiService.chatCompletionStream(history, temperature)) {
            fullResponse += chunk;
            res.write(chunk);
        }

        // Save AI response to mongo
        if (fullResponse) {
            session.messages.push({ role: 'assistant', content: fullResponse });
            await session.save();
        }

        res.end();
    } catch (err) {
        console.error('Stream Controller Error:', err);
        if (!res.headersSent) {
            res.status(500).json({ success: false, message: err.message });
        } else {
            res.end();
        }
    }
};

// @desc    Get single session messages
// @route   GET /api/chat/sessions/:id
// @access  Private
exports.getSession = async (req, res) => {
    try {
        const session = await Session.findById(req.params.id);

        if (!session) {
            return res.status(404).json({ success: false, message: 'Session not found' });
        }

        if (session.userId.toString() !== req.user.id.toString()) {
            return res.status(401).json({ success: false, message: 'Not authorized' });
        }

        res.status(200).json({ success: true, data: session });
    } catch (err) {
        res.status(400).json({ success: false, message: err.message });
    }
};

// @desc    Delete session
// @route   DELETE /api/chat/sessions/:id
// @access  Private
exports.deleteSession = async (req, res) => {
    try {
        const session = await Session.findById(req.params.id);

        if (!session) {
            return res.status(404).json({ success: false, message: 'Session not found' });
        }

        if (session.userId.toString() !== req.user.id.toString()) {
            return res.status(401).json({ success: false, message: 'Not authorized' });
        }

        await session.deleteOne();
        res.status(200).json({ success: true, data: {}, message: 'Session deleted' });
    } catch (err) {
        res.status(400).json({ success: false, message: err.message });
    }
};

// @desc    Add message and get response (non-stream)
// @route   POST /api/chat/sessions/:id/messages
// @access  Private
exports.createMessage = async (req, res) => {
    try {
        const session = await Session.findById(req.params.id);

        if (!session) {
            return res.status(404).json({ success: false, message: 'Session not found' });
        }

        if (session.userId.toString() !== req.user.id.toString()) {
            return res.status(401).json({ success: false, message: 'Not authorized' });
        }

        const { role, content, language, tone, length, temperature } = req.body;

        // Add user message to mongo
        session.messages.push({ role, content });
        await session.save();

        // Prepare prompt
        const history = session.messages.slice(-10).map(m => ({
            role: m.role,
            content: m.content
        }));

        const systemPrompt = `You are Black, a helpful AI assistant. 
Response Requirements:
- Language: ${language || 'English'}
- Tone: ${tone || 'Friendly'}
- Detail Level: ${length || 'Detailed'}`;

        history.unshift({ role: 'system', content: systemPrompt });

        const aiResponse = await aiService.chatCompletion(history, temperature);

        // Save AI response to mongo
        const assistantMessage = { role: 'assistant', content: aiResponse };
        session.messages.push(assistantMessage);
        await session.save();

        res.status(200).json({ success: true, data: assistantMessage });
    } catch (err) {
        res.status(400).json({ success: false, message: err.message });
    }
};

// @desc    Generate title for session
// @route   POST /api/chat/sessions/:id/title
// @access  Private
exports.generateTitle = async (req, res) => {
    try {
        const session = await Session.findById(req.params.id);
        if (!session) {
            return res.status(404).json({ success: false, message: 'Session not found' });
        }

        const firstMessage = session.messages.find(m => m.role === 'user')?.content || 'New Chat';

        const systemPrompt = 'Generate a short, concise title (max 4-5 words) for a chat session based on the following user message. Do not use quotes or punctuation. Just the title.';
        const messages = [
            { role: 'system', content: systemPrompt },
            { role: 'user', content: firstMessage }
        ];

        const title = await aiService.chatCompletion(messages);

        session.title = title.trim().replace(/["']/g, '');
        await session.save();

        res.status(200).json({ success: true, data: session.title });
    } catch (err) {
        res.status(400).json({ success: false, message: err.message });
    }
};
