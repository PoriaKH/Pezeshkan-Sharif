const {generateJwtToken, validateJwtToken} = require('../../utils/jwt');


function auth_requests(app, db, jsonParser) {
    /**
     * @swagger
     * /auth/register:
     *   post:
     *     summary: Register
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             properties:
     *               ssid: string
     *               first_name: string
     *               last_name: string
     *               password: string
     *               repeat_password: string
     *               referrer: string
     *               medical_id: string
     *               user_type: string
     *             example:
     *               ssid: 1234567890
     *               first_name: fname
     *               last_name: lname
     *               password: passpass123
     *               repeat_password: passpass123
     *               referrer: 1234567892
     *               medical_id: 12345
     *               user_type: doctor
     *     responses:
     *       201:
     *         description: Successful register.
     *       401:
     *         description: An error occurred during register. Messages in body.
     *       404:
     *         description: Referrer not Found.
     *
     */
    app.post('/auth/register', jsonParser, async function (req, res) {
        const {ssid, first_name, last_name, password, repeat_password, medical_id, referrer, user_type} = req.body;
        const {rowCount} = await db.query(`select * from public."user" where ssid='${ssid}'`);

        if (rowCount > 0) {
            res.status(401).send('SSID should be Unique.')
        } else if (password !== repeat_password) {
            res.status(401).send('Password and Repeat Password should match.')
        } else if (password.length < 8) {
            res.status(401).send('Password should be at least 8 characters long.')
        } else if (!['doctor', 'patient', 'referrer'].includes(user_type)) {
            res.status(401).send("User Type should be between 'doctor', 'patient', 'referrer'.")
        } else if (user_type === 'doctor' && (medical_id || '').length === 0) {
            res.status(401).send("Medical ID is required for doctors.")
        } else if (user_type !== 'referrer' && (referrer || '').length === 0) {
            res.status(401).send("Referrer is required.")
        } else {
            const keys = ['ssid', 'first_name', 'last_name', 'password'];
            const values = [ssid, first_name, last_name, password];
            if (user_type !== 'referrer') {
                const {rowCount} = await db.query(`select * from public."referrer" where ssid='${referrer}'`)
                if (rowCount === 0) return res.status(404).send('Referrer not Found!')
                keys.push('referrer');
                values.push(referrer);
            }
            if (user_type === 'doctor') {
                keys.push('medical_id');
                values.push(medical_id);
                const {rowCount} = await db.query(`select * from public."doctor_v1" where medical_id='${medical_id}'`);
                if (rowCount > 0) return res.status(401).send('Medical ID should be Unique.')
            } else if (user_type === 'referrer') {
                // referrer is verified by default
                keys.push('is_verified');
                values.push(true);
            }

            await db.query({
                text: `insert into public.${user_type} ` +
                    `(${keys.join(', ')}) ` +
                    `values (${values.map((_, i) => `\$${i + 1}`).join(', ')})`,
                values: values,
            }).catch(console.log);
            res.status(201).send('Register Successful!');
        }
    });

    /**
     * @swagger
     * /auth/login:
     *   post:
     *     summary: Login
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             properties:
     *               ssid: string
     *               password: string
     *             example:
     *               ssid: 1234567890
     *               password: passpass123
     *     responses:
     *       200:
     *         description: Successful login with token cookie.
     *       401:
     *         description: An error occurred during login. Messages in body.
     *
     */
    app.post('/auth/login', jsonParser, async function (req, res) {
        const {ssid, name, password} = req.body;
        let user_type = 'doctor';
        let {rowCount, rows} = await db.query(`select * from public."doctor" where ssid='${ssid}' and password='${password}'`);
        if (rowCount === 0) {
            user_type = 'patient';
            rows = (await db.query(`select * from public."patient" where ssid='${ssid}' and password='${password}'`))['rows'];
            rowCount = rows.length;
        }
        if (rowCount === 0) {
            user_type = 'referrer';
            rows = (await db.query(`select * from public."referrer" where ssid='${ssid}' and password='${password}'`))['rows'];
            rowCount = rows.length;
        }
        if (rowCount === 0) {
            user_type = 'imaging_center';
            rows = (await db.query(`select * from public."imaging_center" where name='${name}' and password='${password}'`))['rows'];
            rowCount = rows.length;
        }
        if (rowCount === 0) {
            res.status(401).send('Username or Password is incorrect.');
        } else if (!rows[0]['is_verified']) {
            res.status(401).send('Unverified users can\'t login.');
        } else {
            const token = generateJwtToken(ssid);
            db.query({
                text: `insert into public."login_token" (ssid, token, created_at, user_type) values ($1, $2, $3, $4)`,
                values: [user_type === 'imaging_center' ? name : ssid, token, (new Date()).toISOString(), user_type]
            }).then((_) => {
                res.cookie('token', token,
                    process.env['NODE_ENV'] === 'production' ? {httpOnly: false, sameSite: 'none', secure: true} : {});
                res.status(200).send('Login Successful!');
            })
        }
    });

    /**
     * @swagger
     * /auth/refresh:
     *   post:
     *     summary: Refresh Token
     *     responses:
     *       200:
     *         description: Successful refresh token with new token cookie.
     *       401:
     *         description: An error occurred during refresh.
     *
     */
    app.post('/auth/refresh', jsonParser, async function (req, res) {
        let {token} = req.cookies;
        if (validateJwtToken(token)) {
            const {rows} = await db.query(`select ssid from public."login_token" where token='${token}' order by created_at desc limit 1`);
            if (rows.length == 0) return res.status(401).send('Invalid Token!')
            const {ssid, user_type} = rows[0]
            token = generateJwtToken(ssid);
            db.query({
                text: `insert into public.login_token (ssid, token, created_at, user_type) values ($1, $2, $3, $4)`,
                values: [ssid, token, (new Date()).toISOString(), user_type]
            }).then((_) => {
                res.cookie('token', token,
                    process.env['NODE_ENV'] === 'production' ? {httpOnly: false, sameSite: 'none', secure: true} : {});
                res.status(200).send('Refresh Token Successful!');
            })
        } else {
            res.status(401).send('Invalid token.');
        }
    });

    /**
     * @swagger
     * /auth/is_logged_in:
     *   get:
     *     summary: Check if user is logged in
     *     responses:
     *       200:
     *         description: Is Logged in.
     *       401:
     *         description: Is not logged in.
     *
     */
    app.get('/auth/is_logged_in', async (req, res) => {
        let {token} = req.cookies;
        if (!validateJwtToken(token)) {
            return res.status(401).send('Invalid Token!')
        } else {
            const {rows} = await db.query(`select * from public."login_token" where token='${token}' order by created_at desc limit 1`);
            if (rows.length === 0) return res.status(401).send('Invalid Token!')
            const {created_at} = rows[0]
            if ((new Date()).getTime() - created_at.getTime() >= process.env.cookie_max_age) {
                return res.status(401).send('Old Token! Send a GET /auth/refresh request and try again.')
            }
        }
        res.status(200).send('User is logged in!')
    })

    /**
     * @swagger
     * /auth/logout:
     *   delete:
     *     summary: Logout
     *     responses:
     *       204:
     *         description: Successful logout.
     *       401:
     *         description: An error occurred during logout.
     *
     */
    app.delete('/auth/logout', jsonParser, async function (req, res) {
        let {token} = req.cookies;
        if (validateJwtToken(token)) {
            const {rows} = await db.query(`select * from public."login_token" where token='${token}' order by created_at desc limit 1`);
            if (rows.length === 0) return res.status(401).send('Invalid Token!')
            const {ssid, created_at} = rows[0]
            if ((new Date()).getTime() - created_at.getTime() >= process.env.cookie_max_age) {
                return res.status(401).send('Old Token! Send a GET /auth/refresh request and try again.')
            }
            db.query({
                text: `delete from public.login_token where ssid=$1`,
                values: [ssid]
            }).then((_) => res.status(204).send('Logout Successful!'))
        } else {
            res.status(401).send('Invalid token.');
        }
    });
}

module.exports = auth_requests;