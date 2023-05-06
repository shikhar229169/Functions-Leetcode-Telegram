// This example shows how to make a decentralized price feed using multiple APIs

// Arguments can be provided when a request is initated on-chain and used in the request source code as shown below
const userName = args[0]

// build HTTP request objects
const url = `https://leetcode-stats-api.herokuapp.com/${userName}`
console.log(`Sending HTTP request to ${url}`)

const leetcodeRequest = Functions.makeHttpRequest({
  url: url,
  method: "GET",
})

const leetcodeResponse = await leetcodeRequest

if (leetcodeResponse.error) {
  throw Error("Request Failed")
}

const ans = Object.entries(leetcodeResponse.data.submissionCalendar).pop()

let myStr = "No new questions done"

if (ans[0] != args[1] || ans[1] != args[2]) {
  // send message on telegram
  const msg = `${userName} did a new question. Total for today is ${ans[1]}`

  const telegramRequest = Functions.makeHttpRequest({
    url: `https://api.telegram.org/bot${secrets.tokenApi}/sendMessage?chat_id=${secrets.chatId}&text=${msg}`,
    method: "POST",
  })

  const telegramResponse = await telegramRequest

  if (telegramResponse.error) {
    throw Error("Request Failed: Telegram Message")
  }

  myStr = "User did a question and notification sent to Telegram"
}

return Functions.encodeString(myStr)
