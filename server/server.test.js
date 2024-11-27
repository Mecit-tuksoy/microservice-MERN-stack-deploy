import request from 'supertest';
import app from './server.mjs';

describe('GET /', () => {
  it('should return a 200 status code', async () => {
    const res = await request(app).get('/');
    expect(res.statusCode).toBe(200);
  });
});
