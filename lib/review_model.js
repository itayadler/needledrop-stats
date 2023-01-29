const {extractArtistAndAlbum}=require("./reviews_scraper");

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
			db.run("alter table reviews add column pitchfork_genre varchar(255)");
			db.run("alter table reviews add column pitchfork_rank varchar(255)");
		})
		db.close((err)=> {
			if (err) reject(err)
			db = require('knex')({
				client: 'sqlite3',
				connection: {
					filename: dbPath
				}
			});
			resolve(db)
		})
	})
}

function all(db) {
	return db.select().where({pitchfork_genre: null}).table("reviews")
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