// noinspection DuplicatedCode

const {validateJwtToken} = require('../utils/jwt');
const {auth_midware} = require("./middlewares/auth");
const {opg_images_storage, delete_file} = require("../utils/files");
const scheduleMail = require("../utils/mail");

function appointment_requests(app, db, jsonParser) {
    /**
     * @swagger
     * /services:
     *   get:
     *     summary: Get List of services (Optional search)
     *     parameters:
     *       - in: query
     *         name: search
     *         schema:
     *           type: string
     *         description: The query string to search with. if not provided, will return all services
     *     responses:
     *       200:
     *         description: Returns service list as a json.
     *
     */
    app.get('/services', async function (req, res) {
        const {search} = req.query;
        if (search) {
            const {rows} = await db.query({
                text: `select * from public."service" where details like $1`,
                values: [`%${search}%`],
            })
                .catch(console.log);
            res.status(200).json(rows)
        } else {
            const {rows} = await db.query(`select * from public."service"`)
                .catch(console.log);
            res.status(200).json(rows)
        }
    });

    /**
     * @swagger
     * /service/{code}:
     *   get:
     *     summary: Get Service info for code
     *     parameters:
     *       - in: path
     *         name: code
     *         schema:
     *           type: string
     *         description: The code of the service
     *     responses:
     *       200:
     *         description: Returns service as a json.
     *       404:
     *         description: Service not found!
     *
     */
    app.get('/service/:code', async function (req, res) {
        const {code} = req.params;
        const {rowCount, rows} = await db.query({text: 'select * from public."service" where code=$1', values: [code]})
            .catch(console.log);
        if (rowCount === 0) return res.status(404).send('Service not found!')
        res.status(200).json(rows[0])
    });

    /**
     * @swagger
     * /doctors:
     *   get:
     *     summary: Get List of doctors (Optional search)
     *     parameters:
     *       - in: query
     *         name: search
     *         schema:
     *           type: string
     *         description: The query string to search with. if not provided, will return all doctors
     *     responses:
     *       200:
     *         description: Returns doctor list as a json.
     *
     */
    app.get('/doctors', async function (req, res) {
        const {search} = req.query;
        if (search) {
            const {rows} = await db.query({
                text: `select * from public."doctor_v1" where first_name || ' ' || last_name like $1`,
                values: [`%${search}%`],
            })
                .catch(console.log);
            res.status(200).json(rows)
        } else {
            const {rows} = await db.query(`select * from public."doctor_v1"`)
                .catch(console.log);
            res.status(200).json(rows)
        }
    });

    /**
     * @swagger
     * /imaging-centers:
     *   get:
     *     summary: Get List of Imaging Centers (Optional search)
     *     parameters:
     *       - in: query
     *         name: search
     *         schema:
     *           type: string
     *         description: The query string to search with. if not provided, will return all imaging centers
     *     responses:
     *       200:
     *         description: Returns imaging center list as a json.
     *
     */
    app.get('/imaging-centers', async function (req, res) {
        const {search} = req.query;
        if (search) {
            const {rows} = await db.query({
                text: `select * from public."imaging_center_v1" where name like $1`,
                values: [`%${search}%`],
            }).catch(console.log);
            res.status(200).json(rows)
        } else {
            const {rows} = await db.query(`select * from public."imaging_center_v1"`)
                .catch(console.log);
            res.status(200).json(rows)
        }
    });

    /**
     * @swagger
     * /appointments:
     *   get:
     *     summary: if "patient" is set, return all of said patient's appointments; otherwise return current user's appointments
     *     parameters:
     *       - in: query
     *         name: patient
     *         schema:
     *           type: string
     *         description: The patient whose appointments need to be provided
     *     responses:
     *       200:
     *         description: Returns appointment list.
     *       400:
     *         description: Referrer can not have appointments.
     *       401:
     *         description: Unauthorized access. Try logging in or refreshing token.
     *
     */
    app.get('/appointments', async function (req, res) {
        let {token} = req.cookies;

        const {rows} = await db.query(`select * from public."login_token" where token='${token}' order by created_at desc limit 1`);
        const {ssid, created_at, user_type} = rows[0]

        if (!validateJwtToken(token)) {
            res.status(401).send('Invalid Token!')
        } else if ((new Date()).getTime() - created_at.getTime() >= process.env.cookie_max_age) {
            res.status(401).send('Old Token! Send a GET /auth/refresh request and try again.')
        } else {
            const {patient} = req.query;

            if (patient) {
                const {rowCount} = await db.query({text: 'select * from public."patient" where ssid=$1', values: [patient]})
                    .catch(console.log);
                if (rowCount === 0) return res.status(404).send('Patient not found!');

                const {rows: list1} = await db.query(`select * from public."doctor_appointment_v1" where patient='${patient}'`)
                    .catch(console.log);
                const {rows: list2} = await db.query(`select * from public."imaging_center_appointment_v1" where patient='${patient}'`)
                    .catch(console.log);
                res.status(200).json([...list1, ...list2])
            } else {
                if (user_type === 'referrer') return res.status(400).send('Referrer can not have appointments!')

                const {rows: list1} = await db.query(`select * from public."doctor_appointment_v1" where patient='${ssid}' or doctor='${ssid}'`)
                    .catch(console.log);
                const {rows: list2} = await db.query(`select * from public."imaging_center_appointment_v1" where patient='${ssid}' or imaging_center_name='${ssid}'`)
                    .catch(console.log);
                res.status(200).json([...list1, ...list2])
            }
        }
    });

    /**
     * @swagger
     * /appointment:
     *   post:
     *     summary: Create appointment
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             properties:
     *               doctor: string
     *               year: integer
     *               month: integer
     *               day: integer
     *               hour: integer
     *             example:
     *               doctor: 1234567890
     *               year: 2022
     *               month: 10
     *               day: 1
     *               hour: 11
     *     responses:
     *       201:
     *         description: Appointment created successfully.
     *       400:
     *         description: Non-Patient users cannot create appointment or appointment is duplicate
     *       401:
     *         description: Unauthorized access. Try logging in or refreshing token.
     *
     */
    app.post('/appointment', jsonParser, async function (req, res) {
        let {token} = req.cookies;

        const {rows} = await db.query(`select * from public."login_token" where token='${token}' order by created_at desc limit 1`);
        const {ssid, created_at, user_type} = rows[0]

        if (!validateJwtToken(token)) {
            res.status(401).send('Invalid Token!')
        } else if ((new Date()).getTime() - created_at.getTime() >= process.env.cookie_max_age) {
            res.status(401).send('Old Token! Send a GET /auth/refresh request and try again.')
        } else if (user_type !== 'patient') {
            res.status(400).send('Non-Patient users cannot create appointment!')
        } else {
            let {year, month, day, hour, doctor, imaging_center} = req.body;
            month -= 1;
            let greg = new Date(year, month, day, hour)
            const weekday = greg.toLocaleDateString('en-US', {weekday: 'long'}).toLowerCase()

            await db.query({
                text: 'insert into public."time" ' +
                    '(date_time, weekday) values ' +
                    '($1, $2) ' +
                    'on conflict on constraint time_date_time_key do nothing',
                values: [greg, weekday]
            }).catch(console.log);

            const {rows: times} = await db.query(`select id from public."time" where extract(years from date_time)=${year} and extract(months from date_time)=${month+1} and extract(days from date_time)=${day} and extract(hours from date_time)=${hour} and extract(minutes from date_time)=0`)
                .catch(console.log);
            const time_id = times[0]['id']

            if (doctor) {
                await db.query({
                    text: `insert into public."appointment_doctor" (patient, doctor, time) values ($1, $2, $3)`,
                    values: [ssid, doctor, time_id]
                })
                    .then(async (_) => {
                        const {rows} = await db.query({text: 'select * from public."appointment_doctor" where doctor=$1 and time=$2', values: [doctor, time_id]})
                        return scheduleMail(ssid, rows[0]['id'], db);
                    })
                    .then((_) => res.status(201).send('Appointment created successfully!'))
                    .catch((e) => {
                        if (e.constraint === 'appointment_doctor_unique_key')
                            res.status(400).send('Appointment already exists!')
                        else console.log(e);
                    });
            } else if (imaging_center) {
                await db.query({
                    text: `insert into public."appointment_imaging_center" (patient, imaging_center, time) values ($1, $2, $3)`,
                    values: [ssid, imaging_center, time_id]
                })
                    .then(async (_) => {
                        const {rows} = await db.query({text: 'select * from public."appointment_imaging_center" where imaging_center=$1 and time=$2', values: [imaging_center, time_id]})
                        return scheduleMail(ssid, rows[0]['id'], db);
                    })
                    .then((_) => res.status(201).send('Appointment created successfully!'))
                    .catch((e) => {
                        if (e.constraint === 'appointment_imaging_center_unique_key')
                            res.status(400).send('Appointment already exists!')
                        else console.log(e);
                    });
            }
        }
    });

    /**
     * @swagger
     * /appointment/{id}:
     *   put:
     *     summary: Get appointment Info
     *     parameters:
     *       - in: path
     *         name: id
     *         schema:
     *           type: integer
     *         required: true
     *         description: The ID of the appointment
     *     requestBody:
     *       required: true
     *       content:
     *         application/json:
     *           schema:
     *             type: object
     *             properties:
     *               rating: number
     *               services:
     *                 type: array
     *                 items:
     *                   type: string
     *                   format: binary
     *             example:
     *               rating: 3.5
     *               services: ['D1120', 'D2620']
     *     responses:
     *       200:
     *         description: Rating updated successfully
     *       400:
     *         description: Non-Patient users cannot create appointment
     *       404:
     *         description: Appointment not found
     *       401:
     *         description: Unauthorized access. Try logging in or refreshing token.
     *
     */
    app.put('/appointment/:id', jsonParser, async function (req, res) {
        let {token} = req.cookies;

        const {rows} = await db.query(`select * from public."login_token" where token='${token}' order by created_at desc limit 1`);
        if (rows.length === 0) return res.status(401).send('Invalid Token!');
        const {ssid, created_at, user_type} = rows[0]

        if (!validateJwtToken(token)) {
            res.status(401).send('Invalid Token!')
        } else if ((new Date()).getTime() - created_at.getTime() >= process.env.cookie_max_age) {
            res.status(401).send('Old Token! Send a GET /auth/refresh request and try again.')
        } else {
            const {id: appointment_id} = req.params;
            const {rating, services} = req.body;
            let {rows: appointment, rowCount} = await db.query({
                text: '(select id from public."appointment_doctor" where id=$1 and (patient=$2 or doctor=$2))' +
                    'union' +
                    '(select id from public."imaging_center_appointment_v1" where id=$1 and (patient=$2 or imaging_center_name=$2))',
                values: [parseInt(appointment_id), ssid]
            })
                .catch(console.log)

            if (rowCount === 0) return res.status(404).send('Appointment not found!');

            if (rating) {
                if (user_type !== 'patient') return res.status(400).send('Non-Patient users cannot rate appointment!')

                await db.query({text: `update public."appointment" set rating=$1 where id=$2`, values: [rating, parseInt(appointment_id)]})
                    .catch(console.log)
                res.status(200).send('Rating updated successfully!')
            }
            if (services) {
                if (user_type !== 'doctor') return res.status(400).send('Non-Doctor users cannot add notes!')

                await db.query({text: `delete from public."appointment_doctor_service" where appointment=$1`, values: [parseInt(appointment_id)]})
                    .catch(console.log);

                for (const code of services) {
                    const {rowCount} = await db.query({text: 'select * from public."service" where code=$1', values: [code]})
                        .catch(console.log)

                    if (rowCount === 0) return res.status(404).send(`Service "${code}" not found!`)

                    await db.query({text: `insert into public."appointment_doctor_service" (appointment, service) values ($1, $2)`, values: [parseInt(appointment_id), code]})
                        .catch(console.log)
                }

                res.status(200).send('Services updated successfully!')
            }
        }
    });

    /**
     * @swagger
     * /appointment/{id}:
     *   put:
     *     summary: Add rating for appointment
     *     parameters:
     *       - in: path
     *         name: id
     *         schema:
     *           type: integer
     *         required: true
     *         description: The ID of the appointment
     *     responses:
     *       200:
     *         description: Appointment returned as json
     *       404:
     *         description: Appointment not found
     *       401:
     *         description: Unauthorized access. Try logging in or refreshing token.
     *
     */
    app.get('/appointment/:id', async function (req, res) {
        let {token} = req.cookies;

        const {rows} = await db.query(`select * from public."login_token" where token='${token}' order by created_at desc limit 1`);
        if (rows.length === 0) return res.status(401).send('Invalid Token!');
        const {ssid, created_at, user_type} = rows[0]

        if (!validateJwtToken(token)) {
            res.status(401).send('Invalid Token!')
        } else if ((new Date()).getTime() - created_at.getTime() >= process.env.cookie_max_age) {
            res.status(401).send('Old Token! Send a GET /auth/refresh request and try again.')
        } else {
            const {id: appointment_id} = req.params;
            let type = 'doctor'
            let {rows: appointment, rowCount} = await db.query({text: `select * from public."${type}_appointment_v1" where id=$1`, values: [parseInt(appointment_id)]})
                .catch(console.log)

            if (rowCount === 0) {
                type = 'imaging_center'
                const result = await db.query({text: `select * from public."${type}_appointment_v1" where id=$1`, values: [parseInt(appointment_id)]})
                    .catch(console.log)
                appointment = result['rows']
                rowCount = result['rowCount']
            }

            if (rowCount === 0 || ![appointment[0]['patient'], appointment[0]['doctor'], appointment[0]['imaging_center_name']].includes(ssid))
                return res.status(404).send('Appointment not found!')

            res.status(200).json({...appointment[0], type})
        }
    });

    /**
     * @swagger
     * /appointment/{id}/images:
     *   post:
     *     summary: Upload appointment images
     *     parameters:
     *       - in: path
     *         name: id
     *         schema:
     *           type: integer
     *         required: true
     *         description: The ID of the appointment
     *     requestBody:
     *       required: true
     *       content:
     *          multipart/form-data:
     *             schema:
     *               type: object
     *               properties:
     *                 images:
     *                   type: array
     *                   items:
     *                     type: string
     *                     format: binary
     *     responses:
     *       201:
     *         description: Images uploaded successfully!
     *       404:
     *         description: Appointment not found
     *       401:
     *         description: Unauthorized access. Try logging in or refreshing token.
     *
     */
    app.post('/appointment/:id/images',
        auth_midware(db, ['imaging_center']),
        opg_images_storage.array('images', 10),
        async function (req, res) {
            const {id: appointment} = req.params;

            if (process.env.NODE_ENV === 'production') {
                const files = req.files;
                await Promise.all(
                    files.map((file) => `https://pezeshkan-sharif.liara.run/${file.path}`)
                        .map((link) => db.query({
                            text: `insert into public."opg_image" (appointment, image_link) values ($1, $2)`,
                            values: [appointment, link]
                        }))
                );
            }
            res.status(201).send('Images Uploaded successfully!');
        });

    /**
     * @swagger
     * /appointment/{id}/images:
     *   get:
     *     summary: Get appointment images
     *     parameters:
     *       - in: path
     *         name: id
     *         schema:
     *           type: integer
     *         required: true
     *         description: The ID of the appointment
     *     responses:
     *       200:
     *         description: Appointment returned as json
     *       404:
     *         description: Appointment not found
     *       401:
     *         description: Unauthorized access. Try logging in or refreshing token.
     *
     */
    app.get('/appointment/:id/images', async function (req, res) {
        let {token} = req.cookies;

        const {rows} = await db.query(`select * from public."login_token" where token='${token}' order by created_at desc limit 1`);
        if (rows.length === 0) return res.status(401).send('Invalid Token!');
        const {ssid, created_at, user_type} = rows[0]

        if (!validateJwtToken(token)) {
            res.status(401).send('Invalid Token!')
        } else if ((new Date()).getTime() - created_at.getTime() >= process.env.cookie_max_age) {
            res.status(401).send('Old Token! Send a GET /auth/refresh request and try again.')
        } else {
            const {id: appointment_id} = req.params;
            let type = 'doctor'
            let {rowCount} = await db.query({text: `select * from public."${type}_appointment_v1" where id=$1`, values: [parseInt(appointment_id)]})
                .catch(console.log)

            if (rowCount === 0) {
                type = 'imaging_center'
                const result = await db.query({text: `select * from public."${type}_appointment_v1" where id=$1`, values: [parseInt(appointment_id)]})
                    .catch(console.log)
                rowCount = result['rowCount']
            }

            if (rowCount === 0)
                return res.status(404).send('Appointment not found!')

            const {rows: list} = await db.query({text: 'select image_link from public."opg_image" where appointment=$1', values: [parseInt(appointment_id)]})
                .catch(console.log)
            res.status(200).json(list.map((i) => i['image_link']));
        }
    });

    /**
     * @swagger
     * /appointment/{id}/images/{filename}:
     *   delete:
     *     summary: Get appointment images
     *     parameters:
     *       - in: path
     *         name: id
     *         schema:
     *           type: integer
     *         required: true
     *         description: The ID of the appointment
     *       - in: path
     *         name: filename
     *         schema:
     *           type: string
     *         required: true
     *         description: The Name of the file to be deleted
     *     responses:
     *       204:
     *         description: Image deleted successfully
     *       404:
     *         description: Appointment or image not found
     *       401:
     *         description: Unauthorized access. Try logging in or refreshing token.
     *
     */
    app.delete('/appointment/:id/images/:filename', async function (req, res) {
        let {token} = req.cookies;

        const {rows} = await db.query(`select * from public."login_token" where token='${token}' order by created_at desc limit 1`);
        if (rows.length === 0) return res.status(401).send('Invalid Token!');
        const {ssid, created_at, user_type} = rows[0]

        if (!validateJwtToken(token)) {
            res.status(401).send('Invalid Token!')
        } else if ((new Date()).getTime() - created_at.getTime() >= process.env.cookie_max_age) {
            res.status(401).send('Old Token! Send a GET /auth/refresh request and try again.')
        } else if (user_type !== 'imaging_center') {
            res.status(400).send('Non-Image-Center users cannot delete appointment images!')
        } else {
            const {id: appointment, filename} = req.params;

            const {rowCount: count1} = await db.query(`select * from public."appointment" where id=${appointment}`)
                .catch(console.log);
            if (count1 === 0) return res.status(404).send('Appointment not found!')

            const {rows: images, rowCount: count2} = await db.query(`select * from public."opg_image" where appointment=${appointment} and image_link like '\%${filename}'`)
                .catch(console.log);

            const file = `files/opg-images/${appointment}/${filename}`;
            delete_file(file)

            if (count2 === 0) return res.status(404).send('Image not found!')
            await db.query(`delete from public."opg_image" where image_link='${images[0]['image_link']}'`)
                .catch(console.log);
            res.status(204).send('Image deleted successfully!')
        }
    });
}

module.exports = appointment_requests;