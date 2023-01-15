// "review_name": "quickly, quickly - The Long and Short of It",
// "youtube_id": "JLfSAHlNrBI",
// "created_at": "2021-09-27T00:00:00.000Z",
// "review_url": "https://www.theneedledrop.com/articles/2021/9/quickly-quickly-the-long-and-short-of-it",
// "youtube_description": "Listen: https://quicklyquickly.bandcamp.com/album/the-long-and-short-of-it\n\nThis album's pretty good and shows potential; that's the long and short of it.\n\nMore pop reviews: https://www.youtube.com/playlist?list=PLP4CSgl7K7oqibt_5oDPppWxQ0iaxyyeq\n\n===================================\nSubscribe: http://bit.ly/1pBqGCN\n\nPatreon: https://www.patreon.com/theneedledrop\n\nOfficial site: http://theneedledrop.com\n\nTwitter: http://twitter.com/theneedledrop\n\nInstagram: https://www.instagram.com/afantano\n\nTikTok: https://www.tiktok.com/@theneedletok\n\nTND Twitch: https://www.twitch.tv/theneedledrop\n===================================\n\nFAV TRACKS: PHASES, SHEE, LEAVE IT, FEEL, EVERYTHING IS DIFFERENT, WY\n\nLEAST FAV TRACK: A CONVERSATION\n\nQUICKLY, QUICKLY - THE LONG AND SHORT OF IT / 2021 / GHOSTLY INTERNATIONAL / ALTERNATIVE R&B, BEDROOM POP, NU JAZZ\n\n7/10\n\nY'all know this is just my opinion, right?",
// "rank": 7,
// "artist_name": "quickly, quickly",
// "album_name": "The Long and Short of It"
const { Database } = require("sqlite3").verbose()

async function createDb(dbPath) {
	return new Promise((resolve, reject)=> {
		let db = new Database(dbPath);
		db.serialize(()=> {
			db.run("CREATE TABLE IF NOT EXISTS reviews (youtube_id VARCHAR(20), review_name VARCHAR(255), created_at VARCHAR(255), review_url VARCHAR(2048), youtube_description TEXT, rank REAL, artist_name VARCHAR(255), album_name VARCHAR(255))");
			db.run("CREATE UNIQUE INDEX IF NOT EXISTS review_youtube_id_index ON reviews(youtube_id)");
			db.run("alter table reviews add column spotify_followers int");
			db.run("alter table reviews add column spotify_artist_id varchar(255)");
			db.run("alter table reviews add column spotify_artist_url varchar(1024)");
			db.run("alter table reviews add column spotify_artist_image varchar(1024)");
			db.run("alter table reviews add column spotify_genre varchar(255)");
		})
		db.close((err)=> {
			if (err) reject(err)
			db = require('knex')({
				client: 'sqlite3', // or 'better-sqlite3'
				connection: {
					filename: dbPath
				}
			});
			resolve(db)
		})
	})
}

function all(db) {
	return db.select().table("reviews")
}

function loadDb(dbPath) {
	return new Promise((resolve, reject)=> {
		const db = require('knex')({
			client: 'sqlite3',
			connection: {
				filename: dbPath
			}
		});
		resolve(db)
	})
}

function create(db, model) {
	return db.insert(model).table("reviews")
}

function update(db, id, model) {
	return db.update(model).where({youtube_id: id}).table("reviews")
}

exports.all = all
exports.createDb = createDb
exports.loadDb = loadDb
exports.create = create
exports.update = update