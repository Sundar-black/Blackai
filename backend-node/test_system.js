// Using global fetch (Node 18+)
async function test() {
    const baseUrl = 'http://localhost:5000/api';
    const email = 'testuser_js@example.com';
    const password = 'password123';

    try {
        console.log('--- Signing up ---');
        const signupRes = await fetch(`${baseUrl}/auth/signup`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ name: 'JS Tester', email, password })
        });
        const signupData = await signupRes.json();
        console.log('Signup:', signupData.success ? 'Success' : signupData.message);

        console.log('\n--- Logging in ---');
        const loginRes = await fetch(`${baseUrl}/auth/login`, {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ email, password })
        });
        const loginData = await loginRes.json();
        const token = loginData.token;
        console.log('Login:', loginData.success ? 'Success' : loginData.message);

        if (!token) throw new Error('No token received');

        console.log('\n--- Creating Session ---');
        const sessionRes = await fetch(`${baseUrl}/chat/sessions`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({ title: 'JS Test Session' })
        });
        const sessionData = await sessionRes.json();

        if (!sessionData.success || !sessionData.data) {
            console.error('Session Creation Failed:', JSON.stringify(sessionData, null, 2));
            throw new Error('Session creation failed');
        }

        const sessionId = sessionData.data._id;
        console.log('Session ID:', sessionId);

        console.log('\n--- Sending Message ---');
        const msgRes = await fetch(`${baseUrl}/chat/sessions/${sessionId}/messages`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': `Bearer ${token}`
            },
            body: JSON.stringify({
                role: 'user',
                content: 'Hello AI! Please respond with the word "JS_TEST_SUCCESS" and nothing else.',
                language: 'English',
                tone: 'Formal'
            })
        });
        const msgData = await msgRes.json();

        if (!msgData.success || !msgData.data) {
            console.error('Message Sending Failed:', JSON.stringify(msgData, null, 2));
            throw new Error('Message sending failed');
        }

        console.log('AI Response:', msgData.data.content);

        if (msgData.data.content.includes('JS_TEST_SUCCESS')) {
            console.log('\n✅ CHAT TEST PASSED!');
        } else {
            console.log('\n❌ CHAT TEST FAILED (Response mismatch)');
        }

    } catch (err) {
        console.error('\n❌ TEST ERROR:', err.message);
    }
}

test();
