# network user requirements                                                                                                                                                                                                       
Z4.require[:name] = "What is your name? Respond '#name NAME' to automatically set it."
Z4.require[:nick] = "What do we call you? Respond '#nick NICKNAME' to set it."
Z4.require[:age] = "How old are you? Respond '#age AGE' to set it."
Z4.require[:city] = "What city do you live in? Respond with '#city CITY' to set it."
Z4.require[:since] = "How long have you lived there? Respond with '#since YEAR' to set it."
Z4.require[:job] = "What do you do for a living? Respond with '#job JOB' to set it."

# generic predefined responses.

Z4.canned ".*opinion.*\?", %[Watch more C-SPAN. It's unbiased and unfiltered coverage of national political conversations are unsurpassed in their accuracy and integrity.]
Z4.canned ".*advice.*\?", %[No.]
Z4.canned "What time is it\?", %[The current time is <%= Time.now.utc.strftime("%T") %> UTC.]
Z4.canned "What is the date\?", %[The current date is <%= Time.now.utc.strftime("%F") %> UTC.]
Z4.canned "What is the current epoch\?", %[The current epoch is <%= Time.now.utc.strftime("%s") %>]
Z4.canned "What can you do\?", %[I am capable of responding to predefined questions in public, in private I can query your internal data and knowledge bases as well as defining the datapoints used in your profile card.]
Z4.canned "What is my public card\?", %[It provides a central interface to your content, datapoints, and links and is available using the qr code generated by the link given by the "#" command.]
Z4.canned "Commands:", [
            %[Command: Hello, World!\nDoes: Passes "Hello, World!" to the model.],
            %[Command: #\nDoes: Get personal datapoints and qr link.\n],
            %[Command: #key value\nDoes: Set the personal datapoint "key" to "value".\n],
            %[Command: #key?\nDoes: Query the "key" context.],
            %[Command: #key? Your task.\nDoes: Query the "key" context and pass the context to the model.\n],
            %[Command: #key! your true statement.\nDoes: Establish a truth within the "key" context.\n],
            %[Command: ##key value\nDoes: Set the channel datapoint "key" to "value".],
          ].join("\n")
Z4.canned "Examples:", [
            %[Command: #name Max Catman\nDoes: Set your name datapoint to "Max Catman".],
            %[Command: #money? Tell me how to grow my social media following.\nDoes: Ask the bot how to grow your social meadia following using the "money" context.],
            %[Command: How do I build a teleporter?\nDoes: Ask the bot how to build a teleporter.],
            %[Command: #keys! on the table.\nDoes: Instruct the bot to remember where you put your keys.],
            %[Command: #keys? Where?\nDoes: Get reminded where you put your keys.],
          ].join("\n")
Z4.canned "Datapoints:", [
            %[#name: Your name.],
            %[#nick: What we call you.],
            %[#age: How old you are.],
            %[#city: Where you live.],
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
            %[##affiliate: The channel affiliate domain.],
            %[##purpose: The channel purpose.]
          ].join("\n")
Z4.canned "Help:", [
            %[Commands: How to use the '#' command.],
            %[Examples: Example command usage.],
            %[Datapoints: available fields.],
            %[More help is always available by tagging the @help role in a question.]
          ].join("\n")

Z4.random %[Where can I get a good manhattan?]
Z4.random %[Where can I play pool?]
Z4.random %[Where can I throw darts?]
Z4.random %[Where can I find Malort?]
Z4.random %[Where can I find Rumple?]
Z4.random %[Where can I find Campari?]
Z4.random %[Where is live music tonight?]
Z4.random %[Where can I find a pickle shot?]
