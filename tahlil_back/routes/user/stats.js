const {validateJwtToken} = require('../../utils/jwt');

function stats_requests(app, db, jsonParser) {
    /**
     * @swagger
     * /stats:
     *   get:
     *     summary: Get User Stats
     *     responses:
     *       200:
     *         description: Returns user statistics as a json.
     *       401:
     *         description: Unauthorized access. Try logging in or refreshing token.
     *
     */
    app.get('/stats', async function (req, res) {
        let {token} = req.cookies;

        const {rows} = await db.query(`select * from public."login_token" where token='${token}' order by created_at desc limit 1`);
        if (rows.length === 0) return res.status(401).send('Invalid Token!')
        let {ssid, created_at, user_type} = rows[0]

        if (!validateJwtToken(token)) {
            res.status(401).send('Invalid Token!')
        } else if ((new Date()).getTime() - created_at.getTime() >= process.env.cookie_max_age) {
            res.status(401).send('Old Token! Send a GET /auth/refresh request and try again.')
        } else {
            res.status(200).json(await get_statistics(db, ssid, user_type))
        }
    });
}

async function get_statistics(db, ssid, user_type) {
    const statistics = {}

    if (['doctor', 'imaging_center'].includes(user_type)) {
        const id = user_type === 'doctor' ? 'doctor' : 'imaging_center_name';
        await db.query({
            text: `select rating::integer, count(*) from public."${user_type}_appointment_v1"` +
                `where ${id}=$1 and rating is not null ` +
                `group by rating::integer`,
            values: [ssid]
        })
            .then(({rows}) => statistics['grouped_ratings'] = rows)
            .catch(console.log);

        await db.query({
            text: `select avg(rating::integer) from public."${user_type}_appointment_v1"` +
                `where ${id}=$1 and rating is not null`,
            values: [ssid]
        })
            .then(({rows}) => statistics['avg_rating'] = rows[0]['avg'])
            .catch(console.log);

        await db.query({
            text: `select extract(day from date_time) as day,` +
                `count(*)` +
                `from public."${user_type}_appointment_v1"` +
                `where ${id}=$1 and extract(month from date_time)=extract(month from now()) ` +
                `group by day`,
            values: [ssid]
        })
            .then(({rows}) => statistics['grouped_appointments_this_month'] = rows)
            .catch(console.log);

        await db.query({
            text: `select extract(month from date_time) as month,` +
                `count(*)` +
                `from public."${user_type}_appointment_v1"` +
                `where ${id}=$1 and extract(year from date_time)=extract(year from now()) ` +
                `group by month`,
            values: [ssid]
        })
            .then(({rows}) => statistics['grouped_appointments_this_year'] = rows)
            .catch(console.log);

        await db.query({
            text: `select extract(year from date_time) as year,` +
                `count(*)` +
                `from public."${user_type}_appointment_v1"` +
                `where ${id}=$1 ` +
                `group by year`,
            values: [ssid]
        })
            .then(({rows}) => statistics['grouped_appointments_by_year'] = rows)
            .catch(console.log);
    }

    if (user_type === 'doctor') {
        await db.query({
            text: `select extract(year from age(patient_birth_date)) as age, count(distinct patient) from public."doctor_appointment_v1"` +
                `where doctor=$1 and patient_birth_date is not null ` +
                `group by age`,
            values: [ssid]
        })
            .then(({rows}) => statistics['grouped_patients_by_age'] = rows)
            .catch(console.log);

        await db.query({
            text: `select repeat_count, count(*) from ` +
                `(select patient, count(*) as repeat_count from public."doctor_appointment_v1" where doctor=$1 group by patient) ` +
                `group by repeat_count`,
            values: [ssid]
        })
            .then(({rows}) => statistics['grouped_repeat_count'] = rows)
            .catch(console.log);
    }

    if (user_type === 'referrer') {
        await db.query({
            text: `select ` +
                `case when is_verified then 'verified' when is_declined then 'declined' else 'waiting' end as status,` +
                `count(*) from public."user" where referrer=$1 group by status`,
            values: [ssid]
        })
            .then(({rows}) => statistics['referee_percentages'] = rows)
            .catch(console.log);
    }

    return statistics;
}

module.exports = stats_requests;