const { loadDb, all, update } = require('./lib/review_model')
const { extractRankFromYt, pitchforkSearch, extractArtistAndAlbum } = require('./lib/reviews_scraper')
const spotify = require("spotify-web-api-node")
const spotifyApi = new spotify()
const bluebird = require('bluebird')
spotifyApi.setAccessToken(process.env.SPOTIFY_ACCESS_TOKEN)
/*
pitchfork genres: ["electronic", "folk/country", "jazz", "pop/r&b", "rock", "experimental", "global", "metal", "rap / hip-hop"]
*/

// const PITCHFORK_GENRES = ["electronic", "country", "jazz", "pop/r&b", "rock", "experimental", "global", "metal", "rap"]
// function includesPartialGenre(genres, genre) {
// 	return genres.find(g => g.includes(genre))
// }
// function spotifyGenresToPitchforkGenre(genres) {
// 	if(includesPartialGenre(genres, "rap") || includesPartialGenre(genres, "hip hop")) return "rap"
// 	if(includesPartialGenre(genres, "jazz")) return "jazz"
// 	if(includesPartialGenre(genres, "rock") || !includesPartialGenre(genres, "metal")) return "rock"
// 	if(includesPartialGenre(genres, "metal")) return "metal"
// 	if(includesPartialGenre(genres, "eletron") || includesPartialGenre(genres, "ambient")) return "electronic"
// 	if(includesPartialGenre(genres, "folk") || includesPartialGenre(genres, "country")) return "country"
// 	if(includesPartialGenre(genres, "pop") || includesPartialGenre(genres, "r-n-b") || includesPartialGenre(genres, "funk") || includesPartialGenre(genres, "soul")) return "pop"
// 	if(includesPartialGenre(genres, "experimental")) return "experimental"
// 	return "global"
// }

async function getArtistData(artistName) {
	const resp = await spotifyApi.searchArtists(artistName)
	const firstResult = resp.body.artists?.items[0]
	if (firstResult) {
		return {
			spotify_followers: firstResult.followers.total,
			spotify_artist_id: firstResult.id,
			spotify_artist_url: firstResult.href,
			spotify_artist_image: firstResult.images[0]?.url,
			spotify_genre: firstResult.genres[0],
		}
	} else {
		return null
	}
}

async function saveAllArtistsToDb(dbPath) {
  const db = await loadDb(dbPath)
	const data = await all(db)
	let cont = true
	// let cont = false
	bluebird.each(data, async (artistData)=> {
		const {youtube_id, artist_name, album_name, review_name, youtube_description} = artistData
		console.log("get pitchfork data for: ", artist_name, album_name)
		// if(artist_name.includes("OFWGKTA")) cont = true
		if (cont) {
			const data = await pitchforkSearch(artist_name)
			if(data) {
				await update(db, youtube_id, data)
				console.log("saved artist data to db!")
			} else {
				console.log("no pitchfork data")
			}
		}
	})
}

saveAllArtistsToDb("./public/tndstats.db")
