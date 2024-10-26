const {validateJwtToken} = require('../../utils/jwt');

function verify_requests(app, db, jsonParser) {
    /**
     * @swagger
     * /referees:
     *   get:
     *     summary: Get a list of all patients and doctors that need current referrer's verification
     *     responses:
     *       200:
     *         description: Returns list of said users as a json.
     *       401:
     *         description: Unauthorized access. Try logging in or refreshing token.
     *
     */
    app.get('/referees', async function (req, res) {
        let {token} = req.cookies;

        const {rows} = await db.query(`select * from public."login_token" where token='${token}' order by created_at desc limit 1`);
        if (rows.length == 0) return res.status(401).send('Invalid Token!');
        const {ssid, created_at, user_type} = rows[0]

        if (!validateJwtToken(token)) {
            res.status(401).send('Invalid Token!')
        } else if ((new Date()).getTime() - created_at.getTime() >= process.env.cookie_max_age) {
            res.status(401).send('Old Token! Send a GET /auth/refresh request and try again.')
        } else if (user_type != 'referrer') {
            res.status(401).send('You have to be a referrer to access this part!')
        } else {
            const {rows: results} = await db.query({text: `select *, 'doctor' as user_type from public."doctor" where referrer=$1`, values: [ssid]})
                .catch(console.log);
            await db.query({text: `select *, 'patient' as user_type from public."patient" where referrer=$1`, values: [ssid]})
                .then(({rows}) => rows.forEach((e) => results.push(e)))
                .catch(console.log);
            await db.query({text: `select *, 'imaging_center' as user_type from public."imaging_center" where referrer=$1`, values: [ssid]})
                .then(({rows}) => rows.forEach((e) => results.push(e)))
                .catch(console.log);

            res.status(200).send(results)
        }
    });

    /**
     * @swagger
     * /referees/users/{ssid}/accept:
     *   post:
     *     summary: Accept the user with the given ssid
     *     parameters:
     *       - in: path
     *         name: ssid
     *         schema:
     *           type: string
     *         required: true
     *         description: The SSID of the user that the referrer wants to verify
     *     responses:
     *       200:
     *         description: Accepted user successfully.
     *       404:
     *         description: User not found.
     *       401:
     *         description: Unauthorized access. Try logging in or refreshing token.
     *
     */
    app.post('/referees/users/:ssid/accept', async function (req, res) {
        let {ssid: user_ssid} = req.params;
        let {token} = req.cookies;

        const {rows} = await db.query(`select * from public."login_token" where token='${token}' order by created_at desc limit 1`);
        if (rows.length == 0) return res.status(401).send('Invalid Token!');
        const {ssid, created_at, user_type} = rows[0]

        if (!validateJwtToken(token)) {
            res.status(401).send('Invalid Token!')
        } else if ((new Date()).getTime() - created_at.getTime() >= process.env.cookie_max_age) {
            res.status(401).send('Old Token! Send a GET /auth/refresh request and try again.')
        } else if (user_type != 'referrer') {
            res.status(401).send('You have to be a referrer to access this part!')
        } else {
            await db.query({text: `update public."user" set is_declined=false, is_verified=true where ssid=$1 and referrer=$2 and not is_verified`, values: [user_ssid, ssid]})
                .then(({rowCount}) => {
                    if (rowCount == 0) return res.status(404).send('Unverified user with ssid not found!')
                    res.status(200).send('User Accepted Successfully!')
                })
                .catch(console.log);
        }
    });

    /**
     * @swagger
     * /referees/users/{ssid}/decline:
     *   post:
     *     summary: Decline the user with the given ssid
     *     parameters:
     *       - in: path
     *         name: ssid
     *         schema:
     *           type: string
     *         required: true
     *         description: The SSID of the user that the referrer wants to decline
     *     responses:
     *       200:
     *         description: Declined user successfully.
     *       404:
     *         description: User not found.
     *       401:
     *         description: Unauthorized access. Try logging in or refreshing token.
     *
     */
    app.post('/referees/users/:ssid/decline', async function (req, res) {
        let {ssid: user_ssid} = req.params;
        let {token} = req.cookies;

        const {rows} = await db.query(`select * from public."login_token" where token='${token}' order by created_at desc limit 1`);
        if (rows.length == 0) return res.status(401).send('Invalid Token!');
        const {ssid, created_at, user_type} = rows[0]

        if (!validateJwtToken(token)) {
            res.status(401).send('Invalid Token!')
        } else if ((new Date()).getTime() - created_at.getTime() >= process.env.cookie_max_age) {
            res.status(401).send('Old Token! Send a GET /auth/refresh request and try again.')
        } else if (user_type != 'referrer') {
            res.status(401).send('You have to be a referrer to access this part!')
        } else {
            await db.query({text: `update public."user" set is_declined=true, is_verified=false where ssid=$1 and referrer=$2`, values: [user_ssid, ssid]})
                .then(({rowCount}) => {
                    if (rowCount == 0) return res.status(404).send('User with ssid not found!')
                    res.status(200).send('User Declined Successfully!')
                })
                .catch(console.log);
        }
    });

    /**
     * @swagger
     * /referees/imaging-centers/{id}/accept:
     *   post:
     *     summary: Accept the Imaging Center with the given id
     *     parameters:
     *       - in: path
     *         name: id
     *         schema:
     *           type: string
     *         required: true
     *         description: The ID of the Imaging Center that the referrer wants to verify
     *     responses:
     *       200:
     *         description: Accepted Imaging Center successfully.
     *       404:
     *         description: Imaging Center not found.
     *       401:
     *         description: Unauthorized access. Try logging in or refreshing token.
     *
     */
    app.post('/referees/imaging-centers/:id/accept', async function (req, res) {
        let {id} = req.params;
        let {token} = req.cookies;

        const {rows} = await db.query(`select * from public."login_token" where token='${token}' order by created_at desc limit 1`);
        if (rows.length == 0) return res.status(401).send('Invalid Token!');
        const {ssid, created_at, user_type} = rows[0]

        if (!validateJwtToken(token)) {
            res.status(401).send('Invalid Token!')
        } else if ((new Date()).getTime() - created_at.getTime() >= process.env.cookie_max_age) {
            res.status(401).send('Old Token! Send a GET /auth/refresh request and try again.')
        } else if (user_type !== 'referrer') {
            res.status(401).send('You have to be a referrer to access this part!')
        } else {
            await db.query({text: `update public."imaging_center" set is_declined=false, is_verified=true where id=$1 and referrer=$2 and not is_verified`, values: [id, ssid]})
                .then(({rowCount}) => {
                    if (rowCount === 0) return res.status(404).send('Unverified Imaging Center with id not found!')
                    res.status(200).send('Imaging Center Accepted Successfully!')
                })
                .catch(console.log);
        }
    });

    /**
     * @swagger
     * /referees/imaging-centers/{id}/decline:
     *   post:
     *     summary: Decline the Imaging Center with the given id
     *     parameters:
     *       - in: path
     *         name: id
     *         schema:
     *           type: string
     *         required: true
     *         description: The ID of the Imaging Center that the referrer wants to decline
     *     responses:
     *       200:
     *         description: Declined Imaging Center successfully.
     *       404:
     *         description: Imaging Center not found.
     *       401:
     *         description: Unauthorized access. Try logging in or refreshing token.
     *
     */
    app.post('/referees/imaging-centers/:id/decline', async function (req, res) {
        let {id} = req.params;
        let {token} = req.cookies;

        const {rows} = await db.query(`select * from public."login_token" where token='${token}' order by created_at desc limit 1`);
        if (rows.length === 0) return res.status(401).send('Invalid Token!');
        const {ssid, created_at, user_type} = rows[0]

        if (!validateJwtToken(token)) {
            res.status(401).send('Invalid Token!')
        } else if ((new Date()).getTime() - created_at.getTime() >= process.env.cookie_max_age) {
            res.status(401).send('Old Token! Send a GET /auth/refresh request and try again.')
        } else if (user_type !== 'referrer') {
            res.status(401).send('You have to be a referrer to access this part!')
        } else {
            await db.query({text: `update public."imaging_center" set is_declined=true, is_verified=false where id=$1 and referrer=$2`, values: [id, ssid]})
                .then(({rowCount}) => {
                    if (rowCount === 0) return res.status(404).send('Unverified Imaging Center with id not found!')
                    res.status(200).send('Imaging Center Declined Successfully!')
                })
                .catch(console.log);
        }
    });
}

module.exports = verify_requests;