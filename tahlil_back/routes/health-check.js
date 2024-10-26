function healthcheck_request(app) {
    /**
     * @swagger
     * /health-check:
     *   get:
     *     summary: Health-Check
     *     responses:
     *       200:
     *         description: Everything is ok
     *
     */
    app.get('/health-check', (req, res) => res.sendStatus(200));
}

module.exports = healthcheck_request;