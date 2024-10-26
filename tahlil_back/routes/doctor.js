const {validateJwtToken} = require('../utils/jwt');


function doctor_requests(app, db, jsonParser) {
    /**
     * @swagger
     * /doctor/{ssid}:
     *   get:
     *     summary: Get Doctor info
     *     parameters:
     *       - in: path
     *         name: ssid
     *         schema:
     *           type: string
     *         required: true
     *         description: The SSID of the doctor
     *     responses:
     *       200:
     *         description: Doctor info returned successfully.
     *       404:
     *         description: Doctor not found.
     */
    app.get('/doctor/:ssid', async function (req, res) {
        const {ssid} = req.params;
        const {rows} = await db.query({text: 'select * from public."doctor_v1" where ssid=$1', values: [ssid]})
            .catch(console.log);
        if (rows.length === 0) return res.status(404).send('Doctor not found!')
        res.status(200).json(rows[0]);
    });

    /**
     * @swagger
     * /doctor/{ssid}/working-hours:
     *   get:
     *     summary: Get Doctor Working Hours info
     *     parameters:
     *       - in: path
     *         name: ssid
     *         schema:
     *           type: string
     *         required: true
     *         description: The ID of the Doctor
     *     responses:
     *       200:
     *         description: Doctor Working Hours returned successfully.
     *       404:
     *         description: Doctor not found.
     */
    app.get('/doctor/:ssid/working-hours', async function (req, res) {
        const {ssid} = req.params;
        const {rowCount} = await db.query({text: 'select * from public."doctor" where ssid=$1', values: [ssid]})
            .catch(console.log);
        if (rowCount === 0) return res.status(404).send('Doctor not found!')
        const {rows} = await db.query({text: 'select * from public."doctor_work_times" where doctor=$1', values: [ssid]})
            .catch(console.log);
        res.status(200).json(rows);
    });

    /**
     * @swagger
     * /doctor/{ssid}/filled-times:
     *   get:
     *     summary: Get Doctor Filled Times
     *     parameters:
     *       - in: path
     *         name: ssid
     *         schema:
     *           type: string
     *         required: true
     *         description: The ID of the Doctor
     *     responses:
     *       200:
     *         description: Doctor Filled Times returned successfully.
     *       404:
     *         description: Doctor not found.
     */
    app.get('/doctor/:ssid/filled-times', async function (req, res) {
        const {ssid} = req.params;
        const {rowCount} = await db.query({text: 'select * from public."doctor" where ssid=$1', values: [ssid]})
            .catch(console.log);
        if (rowCount === 0) return res.status(404).send('Doctor not found!')
        const {rows} = await db.query({text: 'select date_time, weekday from public."doctor_appointment_v1" where doctor=$1', values: [ssid]})
            .catch(console.log);
        res.status(200).json(rows);
    });

    /**
     * @swagger
     * /doctor/work-hours:
     *   put:
     *     summary: Edit Work Hours
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             properties:
     *               saturday: string
     *               sunday: string
     *               monday: string
     *               tuesday: string
     *               wednesday: string
     *               thursday: string
     *               friday: string
     *             example:
     *               saturday: 8-12,16-20
     *               monday: 15-19
     *     responses:
     *       200:
     *         description: Doctor Work Hours have been edited successfully.
     *       404:
     *         description: Doctor not found.
     *       401:
     *         description: Unauthorized access. Try logging in or refreshing token.
     *
     */
    app.put('/doctor/work-hours', jsonParser, async function (req, res) {
        let {token} = req.cookies;

        const {rows} = await db.query(`select * from public."login_token" where token='${token}' order by created_at desc limit 1`);
        if (rows.length === 0) return res.status(401).send('Invalid Token!')
        const {ssid, created_at, user_type} = rows[0]
        if (!validateJwtToken(token)) {
            res.status(401).send('Invalid Token!')
        } else if ((new Date()).getTime() - created_at.getTime() >= process.env.cookie_max_age) {
            res.status(401).send('Old Token! Send a GET /auth/refresh request and try again.')
        } else if (user_type !== 'doctor') {
            res.status(404).send('Doctor not found!')
        } else {
            const body = req.body;
            await db.query(`delete from public."doctor_work_times" where doctor='${ssid}'`)
                .catch(console.log);
            if (Object.keys(body).length > 0) {
                for (const [wd, times] of Object.entries(body)) {
                    if (!times) continue;

                    for (const range of times.split(',')) {
                        await db.query({
                            text: 'insert into public."doctor_work_times" (doctor, weekday, start_hour, end_hour) values ($1, $2, $3, $4)',
                            values: [ssid, wd, range.split('-')[0], range.split('-')[1]],
                        })
                            .catch(console.log);
                    }
                }
            }
            res.status(200).send('Doctor Work Hours updated Successfully!');
        }
    });
}

module.exports = doctor_requests;