const {validateJwtToken} = require("../utils/jwt");

function imaging_center_requests(app, db, jsonParser) {
    /**
     * @swagger
     * /imaging-center:
     *   post:
     *     summary: Create Imaging Center
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             properties:
     *               name: string
     *               referrer: string
     *               password: string
     *               repeat_password: string
     *             example:
     *               name: imaging center
     *               referrer: 1234567892
     *               password: passpass123
     *               repeat_password: passpass123
     *     responses:
     *       201:
     *         description: Imaging Center Created Successfully.
     *       400:
     *         description: Error in creation
     *       404:
     *         description: Referrer not found
     */
    app.post('/imaging-center', jsonParser, async function (req, res) {
        const {name, password, repeat_password, referrer} = req.body;
        const {rows: referrers} = await db.query('select ssid from public."referrer"');
        const {rowCount} = await db.query(`select * from public."imaging_center" where name='${name}'`);

        if (rowCount > 0) {
            res.status(400).send('Name should be Unique.')
        } else if (!referrers.map((r) => r['ssid']).includes(referrer)) {
            res.status(404).send('Referrer not found.')
        } else if (password !== repeat_password) {
            res.status(400).send('Password and Repeat Password should match.')
        } else if (password.length < 8) {
            res.status(400).send('Password should be at least 8 characters long.')
        } else {
            await db.query({
                text: `insert into public."imaging_center" ` +
                    `(name, referrer, password) ` +
                    `values ($1, $2, $3)`,
                values: [name, referrer, password],
            }).catch(console.log);
            res.status(201).send('Imaging Center Created Successfully!');
        }
    });

    /**
     * @swagger
     * /imaging-center/{id}:
     *   get:
     *     summary: Get Imaging Center info
     *     parameters:
     *       - in: path
     *         name: id
     *         schema:
     *           type: string
     *         required: true
     *         description: The ID of the Imaging Center
     *     responses:
     *       200:
     *         description: Imaging Center info returned successfully.
     *       404:
     *         description: Imaging Center not found.
     */
    app.get('/imaging-center/:id', async function (req, res) {
        const {id} = req.params;
        const {rows} = await db.query({text: 'select * from public."imaging_center_v1" where id=$1', values: [id]})
            .catch(console.log);
        if (rows.length === 0) return res.status(404).send('Imaging Center not found!')
        res.status(200).json(rows[0]);
    });

    /**
     * @swagger
     * /imaging-center/{id}/working-hours:
     *   get:
     *     summary: Get Imaging Center Working Hours
     *     parameters:
     *       - in: path
     *         name: id
     *         schema:
     *           type: string
     *         required: true
     *         description: The ID of the Imaging Center
     *     responses:
     *       200:
     *         description: Imaging Center Working Hours returned successfully.
     *       404:
     *         description: Imaging Center not found.
     */
    app.get('/imaging-center/:id/working-hours', async function (req, res) {
        const {id} = req.params;
        const {rowCount} = await db.query({text: 'select * from public."imaging_center" where id=$1', values: [id]})
            .catch(console.log);
        if (rowCount === 0) return res.status(404).send('Imaging Center not found!')
        const {rows} = await db.query({text: 'select * from public."imaging_center_work_times" where imaging_center=$1', values: [id]})
            .catch(console.log);
        res.status(200).json(rows);
    });

    /**
     * @swagger
     * /imaging-center/{id}/filled-times:
     *   get:
     *     summary: Get Imaging Center Filled Times
     *     parameters:
     *       - in: path
     *         name: id
     *         schema:
     *           type: string
     *         required: true
     *         description: The ID of the Imaging Center
     *     responses:
     *       200:
     *         description: Imaging Center Filled Times returned successfully.
     *       404:
     *         description: Imaging Center not found.
     */
    app.get('/imaging-center/:id/filled-times', async function (req, res) {
        const {id} = req.params;
        const {rowCount} = await db.query({text: 'select * from public."imaging_center" where id=$1', values: [id]})
            .catch(console.log);
        if (rowCount === 0) return res.status(404).send('Imaging Center not found!')
        const {rows} = await db.query({text: 'select date_time, weekday from public."imaging_center_appointment_v1" where imaging_center=$1', values: [id]})
            .catch(console.log);
        res.status(200).json(rows);
    });

    /**
     * @swagger
     * /imaging-center/work-hours:
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
     *         description: Imaging Center Work Hours have been edited successfully.
     *       404:
     *         description: Imaging Center not found.
     *       401:
     *         description: Unauthorized access. Try logging in or refreshing token.
     *
     */
    app.put('/imaging-center/work-hours', jsonParser, async function (req, res) {
        let {token} = req.cookies;

        const {rows} = await db.query(`select * from public."login_token" where token='${token}' order by created_at desc limit 1`);
        if (rows.length === 0) return res.status(401).send('Invalid Token!')
        const {ssid: name, created_at, user_type} = rows[0]
        if (!validateJwtToken(token)) {
            res.status(401).send('Invalid Token!')
        } else if ((new Date()).getTime() - created_at.getTime() >= process.env.cookie_max_age) {
            res.status(401).send('Old Token! Send a GET /auth/refresh request and try again.')
        } else if (user_type !== 'imaging_center') {
            res.status(404).send('Imaging Center not found!')
        } else {
            const body = req.body;
            const {rows} = await db.query(`select id from imaging_center where name='${name}'`)
                .catch(console.log);
            const id = rows[0]['id'];
            await db.query(`delete from public."imaging_center_work_times" where imaging_center=${id}`)
                .catch(console.log);

            if (Object.keys(body).length > 0) {
                for (const [wd, times] of Object.entries(body)) {
                    if (!times) continue;

                    for (const range of times.split(',')) {
                        await db.query({
                            text: 'insert into public."imaging_center_work_times" (imaging_center, weekday, start_hour, end_hour) values ($1, $2, $3, $4)',
                            values: [id, wd, range.split('-')[0], range.split('-')[1]],
                        })
                            .catch(console.log);
                    }
                }
            }
            res.status(200).send('Imaging Center Work Hours updated Successfully!');
        }
    });
}

module.exports = imaging_center_requests;