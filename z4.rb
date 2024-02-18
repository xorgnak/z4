Z4.user[:age] = "How old are you?\nRespond '#age AGE' in the channel you were just in to set it."

Z4.user[:sign] = "What's your sign?\nRespond '#sign ZODIAC' in the channel you were just in to set it."

Z4.user[:name] = "What is your name?\nRespond '#name NAME' to automatically set it."

Z4.user[:nick] = "What do we call you?\nRespond '#nick NICKNAME' to set it."

Z4.user[:job] = "What do you do for a living?\nRespond with '#job JOB' to set it."

Z4.chan[:rate] = "What is the standard rate for this job as equal to one gp?\nRespond '#rate RATE' to set it."

Z4.chan[:license] = "Is this job subject to license?\nRespond '#license yes OR no' to set it."

Z4.chan[:insurence] = "Is this job subject to insurence requirements?\nRespond '#insurence yes OR no' to set it."

Z4.user[:since] = "How long have you done that?\nRespond with '#since YEAR' to set it."

Z4.user[:area] = "What part of town do you work in?\nRespond with '#area AREA' to set it."

Z4.user[:agree] = [
  "User Terms and responsibilities of service.",
  "Henceforth Free Range Holdings, LLC. of Denver, Colorado shall be refered to as WE and you will be referred to as YOU.",
  "- WE will manage the promotion of your personal brand within the utility of the z4 ai framework.",
  "- WE will manage the provided services through an exchangable system of credits known as GP.",
  "- WE will not share your personal information.",
  "- YOU must not share your personal information.",
  "- YOU must not use the provided services to break any applicable laws.",
  "- YOU must not allow the provided services to break any applicable laws.",
  %[Respond '#agree I agree' to agree.]
].join("\n")

Z4.user[:ready] = [
  %[You're all set! Use the '#', '##', and 'Help:' commands to use your profile.],
  %[Respond '#ready ok' to let me know you've read this helpful message.]
].join("\n")

[
  "Downtown Denver, Colorado",
  "Capitol Hill, Denver, Colorado",
  "Five_Points,_Denver, Colorado",
  "Golden_Triangle,_Denver,_Colorado",
  "North_Capitol_Hill,_Denver, Denver, Colorado",
  "Highland,_Denver, Colorado",
  "Denver's_Art_District_on_Santa_Fe, Denver, Colorado"
].each { |e| WIKI[e] }

Z4.chan[:name] = "What do you call this channel?\nRespond '##name NAME' to set it."

Z4.chan[:affiliate] = "What domain does this channel represent?\nRespond '##affiliate DOMAIN' to set it."

Z4.chan[:state] = "What state does your channel operate in?\nRespond with '##state STATE' to set it."

Z4.chan[:city] = "What city does your channel operate in?\nRespond with '##city CITY' to set it."

Z4.chan[:job] = "What job is this channel used for?\nRespond '##job JOB' to set it."

Z4.chan[:rate] = "What is the standard rate for this job as equal to one gp?\nRespond '##rate RATE' to set it."

Z4.chan[:license] = "Is this job subject to license?\nRespond '##license yes OR no' to set it."

Z4.chan[:insurence] = "Is this job subject to insurence requirements?\nRespond '##insurence yes OR no' to set it."

Z4.chan[:color] = "What color represents this channel?\nRespond '##color COLOR' to set it."

Z4.chan[:age] = "How old do you need to be to use this channel?\nRespond '##age AGE' to set it."

Z4.chan[:agree] = [   
  "Channel Terms and responsibilities of service.",
  "Henceforth Free Range Holdings, LLC. of Denver, Colorado shall be refered to as WE and YOU will be referred to as You and the users of your channel.",
  "- WE will manage the promotion of your channel brand within the utility of the z4 ai framework.",
  "- WE will manage the provided services through an exchangable system of credits known as GP.",
  "- WE will not share your channel information.",
  "- YOU must not share your channel information.",
  "- YOU must not use the provided services to break any applicable laws.",
  "- YOU must not allow the provided services to break any applicable laws.",
  %[Respond '##agree I agree' to agree.]
].join("\n")

Z4.chan[:ready] = [
  %[Congradulations on the purchase of your new z4 channel.],
  %[Let me take a moment to show you a couple things for later.],
  %[- Use the ##color datapoint to distinguish different channels on the server.],
  %[- Allow roughly 10 minutes to onboard a new user.],
  %[- Including an amount followed by 'gp' in a channel will send credits to users.],
  %[- Build your server recommendation list by tagging referrals in messages.],
  %[- Invite users to build your team.],
  %[- Onboard new users to build a consistent culture.],
  %[Respond '##ready ok' to let me know you've read this helpful message.]
].join("\n")






Z4.canned ".*opinion.*\?", %[Watch more C-SPAN. It's unbiased and unfiltered coverage of national political conversations are unsurpassed in their accuracy and integrity.]

Z4.canned ".*advice.*\?", %[No.]

Z4.canned "What time is it\?", %[The current time is <%= Time.now.utc.strftime("%T") %> UTC.]

Z4.canned "What is the date\?", %[The current date is <%= Time.now.utc.strftime("%F") %> UTC.]

Z4.canned "What is the current epoch\?", %[The current epoch is <%= Time.now.utc.strftime("%s") %>]

Z4.canned "What can you do\?", %[I am capable of responding to predefined questions, managing internal datapoints and knowledgebases as well as generating your qr badge.]

Z4.canned "What is my badge\?", %[It provides a central interface to your content, datapoints, and links and is available using the qr code generated by the link given by the "##" command.]

Z4.canned "Where is my badge\?",%[User the '##' command from within a channel to get your badge link.  You badge link refers to your user profile.]

Z4.canned "Plan a (.*) for (.*)", %[Ok. I will plan a <%= @matchdata[1] %> using <%= @users %> for <%= @matchdata[2] %>.]

Z4.canned "Commands:", [
            %[Command: Hello, World!\nDoes: Passes "Hello, World!" to the model.],
            %[Command: #\nDoes: Get personal datapoints.\n],
            %[Command: ##\nDoes: Get your badge link.],
            %[Command: #key value\nDoes: Set the personal datapoint "key" to "value".\n],
            %[Command: #tag?\nDoes: Query the "tag" context.],
            %[Command: #tag? Your task.\nDoes: Query the "tag" context and pass the context to the model.\n],
            %[Command: #tag! your true statement.\nDoes: Establish a truth within the "tag" context.\n],
          ].join("\n")

Z4.canned "Examples:", [
            %[Example: #name Max Catman\nDoes: Set your name datapoint to "Max Catman".],
            %[Example: #money? Tell me how to grow my social media following.\nDoes: Ask the bot how to grow your social meadia following using the "money" context.],
            %[Example: How do I build a teleporter?\nDoes: Ask the bot how to build a teleporter.],
            %[Example: #keys! on the table.\nDoes: Instruct the bot to remember where you put your keys.],
            %[Example: #keys? Where?\nDoes: Get reminded where you put your keys.],
          ].join("\n")

Z4.canned "Datapoints:", [
            %[#age: How old you are.],
            %[#name: Your name.],
            %[#nick: What we call you.],
            %[#area: The part of town you work in.],
            %[#zone: The area, city, and state you work in.],
            %[#since: When you moved there.],
            %[#job: What you do for a living.],
            %[#union: The union you are a member of.],
            %[#phone: A quick dial/sms link.],
            %[#social: Your social media link.],
            %[#store: Your web store.],
            %[#tips: Your social tipping link.],
            %[#img: Your background image.],
            %[#embed: Embedded content.],
            %[##name: The channel name.],
            %[##age: Minimum age for channel.],
            %[##state: Channel operating state.],
            %[##city: Channel operating city.],
            %[##color: The channel background color.],
            %[##affiliate: The channel affiliate domain.],
            %[##purpose: The channel purpose.],
            %[##embed: Channel embed content.]
          ].join("\n")

Z4.canned "Help:", [
            %[Commands: How to use the '#' command.],
            %[Examples: Example command usage.],
            %[Datapoints: available fields.],
            %[More help is always available by tagging the @help role in a question.]
          ].join("\n")


#tag-*type-*award
##
# TAG.safe tag, type
# TAG.award tag, award

Z4.tag("local", color: 4, types: ["bar","food","weed","86"], awards: ["best"])

Z4.tag("food", color: 3, types: ["pizza","pasta","sandwich","burger","gyro","fries","eggs","burritos","tacos","vegan","vegetarian","8ball"], awards: ["late","fast"])

Z4.tag("bar",  color: 3, types: ["whiskey","vodka","gin","absenthe","cocktails","wine","beer","pool","darts","food","skiball","hoops","airhockey","thering","door","floor"], awards: ["cool","dance","pub"])

Z4.tag("pool", color: 3, types: ["8ball","9ball"], awards: ["bar","area","city"])

Z4.tag("weed", color: 3, types: ["flower","edible","concentrate"], awards: ["area","city"] )

Z4.tag("86", color: 1, types: ["bar", "town"], awards: ["night", "week", "month", "life"])
