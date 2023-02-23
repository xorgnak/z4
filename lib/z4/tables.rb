
# domain profile
DB.table(:host,
         body: '',
         brands: {},
         teams: {},
         users: {},
         campaigns: {})

# user profile
DB.table(:user,
            name: '',
            title: '',
            level: 0,
            teams: {},
            items: {},
            events: {},
            posts: {},
            brands: {},
            badges: {},
            campaigns: {},
            titles: {}
        )

# collection of users by class scored with work
DB.table(:team,
         exchange: 1,
         credits: 0,
         events: {},
         items: {},
         places: {},
         campaigns: {},
         promotors: {},
         influencers: {},
         ambassadors: {},
         managers: {},
         agents: {},
         operators: {}
)

# brand object
DB.table(:brand,
         host: 'set host in channel',
         body: 'set body in channel.',
         desc: 'set desc in channel.',
         exchange: 1,
         credits: 0,
         badges: {},
         teams: {},
         promotors: {},
         places: {},
         campaigns: {},
         titles: {})

# places
DB.table(:place,
         address: '',
         gps: '',
         info: {},
         data: {},
         scans: {},
         events: {})

# schedling
DB.table(:event,
         place: '',
         channel: '',
         freq: {},
         teams: {})

# item to be delivered on referral
DB.table(:item,
         desc: '',
         cost: 0,
         until: 0,
         created: 0)

# generic blog
DB.table(:post,
         user: '',
         body: '',
         posts: {},
         reactions: {})

# content plan
DB.table(:campaign,
         brand: '',
         team: '',
         date: '<%= Time.now %>',
         time: '00:00',
         place: '',
         item: '',
         method: '',
         value: '',
         influencer: 'influencer',
         ambassador: 'ambassador',
         promotors: {})

DB.table(:visit,
         created: 0,
         last: 0,
         campaign: '',
         user: '',
         team: '',
         brand: '',
         host: '',
         brands: {},
         users: {},
         places: {},
         items: {},
         fingerprint: {}
        )

DB.table(:chan,
         host: 'localhost',
         brand: 'localhost',
         campaign: 'localhost',
         place: 'localhost',
         item: 'localhost',
         plan: 'localhost',
        )
