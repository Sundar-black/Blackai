const OpenAI = require('openai');
const fs = require('fs');
const path = require('path');

// Initialize client lazily to ensure env vars are loaded
let _client;
function getClient() {
    if (!_client) {
        const apiKey = process.env.OPENAI_API_KEY;
        const logData = `--- AI Client Init ---\nKey starts with: ${apiKey ? apiKey.substring(0, 5) : 'MISSING'}\n\n`;
        fs.appendFileSync(path.join(__dirname, '../../debug.log'), logData);

        _client = new OpenAI({
            apiKey: apiKey,
            baseURL: 'https://openrouter.ai/api/v1',
            defaultHeaders: {
                'HTTP-Referer': 'https://blackai.app',
                'X-Title': 'BlackAI',
            }
        });
    }
    return _client;
}

function getModel() {
    return process.env.AI_MODEL || 'google/gemini-2.0-flash-exp';
}

async function* chatCompletionStream(messages, temperature = 0.7) {
    try {
        const client = getClient();
        const model = getModel();

        const response = await client.chat.completions.create({
            model: model,
            messages: messages,
            temperature: parseFloat(temperature),
            stream: true,
        });

        for await (const chunk of response) {
            const content = chunk.choices[0]?.delta?.content || '';
            if (content) {
                yield content;
            }
        }
    } catch (error) {
        console.error('AI Stream Error:', error);
        yield `Error in AI stream: ${error.message}`;
    }
}

const chatCompletion = async (messages) => {
    try {
        const client = getClient();
        const model = getModel();

        const response = await client.chat.completions.create({
            model: model,
            messages: messages,
        });
        return response.choices[0].message.content;
    } catch (error) {
        console.error('AI Completion Error:', error);
        throw error;
    }
};

module.exports = { chatCompletionStream, chatCompletion };
