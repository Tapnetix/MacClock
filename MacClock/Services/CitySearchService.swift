import Foundation

struct CitySearchResult: Identifiable {
    let id = UUID()
    let cityName: String
    let countryName: String
    let timezoneIdentifier: String

    var displayName: String {
        "\(cityName), \(countryName)"
    }
}

actor CitySearchService {
    private lazy var allTimezones: [CitySearchResult] = {
        var results: [CitySearchResult] = []

        for identifier in TimeZone.knownTimeZoneIdentifiers {
            // Skip generic timezones like "GMT", "UTC", etc.
            guard identifier.contains("/") else { continue }

            let components = identifier.split(separator: "/")
            guard components.count >= 2 else { continue }

            let region = String(components[0])
            let cityPart = String(components.last!)

            // Convert underscores to spaces and handle special cases
            let cityName = cityPart
                .replacingOccurrences(of: "_", with: " ")

            let countryName = regionToCountry(region, cityPart: cityPart)

            results.append(CitySearchResult(
                cityName: cityName,
                countryName: countryName,
                timezoneIdentifier: identifier
            ))
        }

        // Sort alphabetically by city name
        return results.sorted { $0.cityName < $1.cityName }
    }()

    func search(query: String) -> [CitySearchResult] {
        guard !query.isEmpty else { return [] }
        let lowercased = query.lowercased()
        return allTimezones.filter {
            $0.cityName.lowercased().contains(lowercased) ||
            $0.countryName.lowercased().contains(lowercased) ||
            $0.timezoneIdentifier.lowercased().contains(lowercased)
        }
    }

    func allCities() -> [CitySearchResult] {
        allTimezones
    }

    private func regionToCountry(_ region: String, cityPart: String) -> String {
        // Map IANA timezone regions to more user-friendly names
        switch region {
        case "Africa":
            return africaCountry(for: cityPart)
        case "America":
            return americaCountry(for: cityPart)
        case "Antarctica":
            return "Antarctica"
        case "Arctic":
            return "Arctic"
        case "Asia":
            return asiaCountry(for: cityPart)
        case "Atlantic":
            return atlanticCountry(for: cityPart)
        case "Australia":
            return "Australia"
        case "Europe":
            return europeCountry(for: cityPart)
        case "Indian":
            return indianCountry(for: cityPart)
        case "Pacific":
            return pacificCountry(for: cityPart)
        default:
            return region
        }
    }

    private func africaCountry(for city: String) -> String {
        let mapping: [String: String] = [
            "Abidjan": "Ivory Coast", "Accra": "Ghana", "Addis_Ababa": "Ethiopia",
            "Algiers": "Algeria", "Asmara": "Eritrea", "Bamako": "Mali",
            "Bangui": "Central African Republic", "Banjul": "Gambia", "Bissau": "Guinea-Bissau",
            "Blantyre": "Malawi", "Brazzaville": "Congo", "Bujumbura": "Burundi",
            "Cairo": "Egypt", "Casablanca": "Morocco", "Ceuta": "Spain",
            "Conakry": "Guinea", "Dakar": "Senegal", "Dar_es_Salaam": "Tanzania",
            "Djibouti": "Djibouti", "Douala": "Cameroon", "El_Aaiun": "Western Sahara",
            "Freetown": "Sierra Leone", "Gaborone": "Botswana", "Harare": "Zimbabwe",
            "Johannesburg": "South Africa", "Juba": "South Sudan", "Kampala": "Uganda",
            "Khartoum": "Sudan", "Kigali": "Rwanda", "Kinshasa": "DR Congo",
            "Lagos": "Nigeria", "Libreville": "Gabon", "Lome": "Togo",
            "Luanda": "Angola", "Lubumbashi": "DR Congo", "Lusaka": "Zambia",
            "Malabo": "Equatorial Guinea", "Maputo": "Mozambique", "Maseru": "Lesotho",
            "Mbabane": "Eswatini", "Mogadishu": "Somalia", "Monrovia": "Liberia",
            "Nairobi": "Kenya", "Ndjamena": "Chad", "Niamey": "Niger",
            "Nouakchott": "Mauritania", "Ouagadougou": "Burkina Faso", "Porto-Novo": "Benin",
            "Sao_Tome": "São Tomé and Príncipe", "Tripoli": "Libya", "Tunis": "Tunisia",
            "Windhoek": "Namibia"
        ]
        return mapping[city] ?? "Africa"
    }

    private func americaCountry(for city: String) -> String {
        let mapping: [String: String] = [
            "Adak": "USA", "Anchorage": "USA", "Anguilla": "Anguilla",
            "Antigua": "Antigua and Barbuda", "Araguaina": "Brazil", "Argentina": "Argentina",
            "Aruba": "Aruba", "Asuncion": "Paraguay", "Atikokan": "Canada",
            "Bahia": "Brazil", "Bahia_Banderas": "Mexico", "Barbados": "Barbados",
            "Belem": "Brazil", "Belize": "Belize", "Blanc-Sablon": "Canada",
            "Boa_Vista": "Brazil", "Bogota": "Colombia", "Boise": "USA",
            "Cambridge_Bay": "Canada", "Campo_Grande": "Brazil", "Cancun": "Mexico",
            "Caracas": "Venezuela", "Cayenne": "French Guiana", "Cayman": "Cayman Islands",
            "Chicago": "USA", "Chihuahua": "Mexico", "Costa_Rica": "Costa Rica",
            "Creston": "Canada", "Cuiaba": "Brazil", "Curacao": "Curaçao",
            "Danmarkshavn": "Greenland", "Dawson": "Canada", "Dawson_Creek": "Canada",
            "Denver": "USA", "Detroit": "USA", "Dominica": "Dominica",
            "Edmonton": "Canada", "Eirunepe": "Brazil", "El_Salvador": "El Salvador",
            "Fort_Nelson": "Canada", "Fortaleza": "Brazil", "Glace_Bay": "Canada",
            "Goose_Bay": "Canada", "Grand_Turk": "Turks and Caicos", "Grenada": "Grenada",
            "Guadeloupe": "Guadeloupe", "Guatemala": "Guatemala", "Guayaquil": "Ecuador",
            "Guyana": "Guyana", "Halifax": "Canada", "Havana": "Cuba",
            "Hermosillo": "Mexico", "Indiana": "USA", "Inuvik": "Canada",
            "Iqaluit": "Canada", "Jamaica": "Jamaica", "Juneau": "USA",
            "Kentucky": "USA", "Kralendijk": "Caribbean Netherlands", "La_Paz": "Bolivia",
            "Lima": "Peru", "Los_Angeles": "USA", "Lower_Princes": "Sint Maarten",
            "Maceio": "Brazil", "Managua": "Nicaragua", "Manaus": "Brazil",
            "Marigot": "Saint Martin", "Martinique": "Martinique", "Matamoros": "Mexico",
            "Mazatlan": "Mexico", "Menominee": "USA", "Merida": "Mexico",
            "Metlakatla": "USA", "Mexico_City": "Mexico", "Miquelon": "Saint Pierre and Miquelon",
            "Moncton": "Canada", "Monterrey": "Mexico", "Montevideo": "Uruguay",
            "Montreal": "Canada", "Montserrat": "Montserrat", "Nassau": "Bahamas",
            "New_York": "USA", "Nipigon": "Canada", "Nome": "USA",
            "Noronha": "Brazil", "North_Dakota": "USA", "Nuuk": "Greenland",
            "Ojinaga": "Mexico", "Panama": "Panama", "Pangnirtung": "Canada",
            "Paramaribo": "Suriname", "Phoenix": "USA", "Port-au-Prince": "Haiti",
            "Port_of_Spain": "Trinidad and Tobago", "Porto_Velho": "Brazil", "Puerto_Rico": "Puerto Rico",
            "Punta_Arenas": "Chile", "Rainy_River": "Canada", "Rankin_Inlet": "Canada",
            "Recife": "Brazil", "Regina": "Canada", "Resolute": "Canada",
            "Rio_Branco": "Brazil", "Santarem": "Brazil", "Santiago": "Chile",
            "Santo_Domingo": "Dominican Republic", "Sao_Paulo": "Brazil", "Scoresbysund": "Greenland",
            "Sitka": "USA", "St_Barthelemy": "Saint Barthélemy", "St_Johns": "Canada",
            "St_Kitts": "Saint Kitts and Nevis", "St_Lucia": "Saint Lucia", "St_Thomas": "US Virgin Islands",
            "St_Vincent": "Saint Vincent and the Grenadines", "Swift_Current": "Canada", "Tegucigalpa": "Honduras",
            "Thule": "Greenland", "Thunder_Bay": "Canada", "Tijuana": "Mexico",
            "Toronto": "Canada", "Tortola": "British Virgin Islands", "Vancouver": "Canada",
            "Whitehorse": "Canada", "Winnipeg": "Canada", "Yakutat": "USA",
            "Yellowknife": "Canada"
        ]
        return mapping[city] ?? "Americas"
    }

    private func asiaCountry(for city: String) -> String {
        let mapping: [String: String] = [
            "Aden": "Yemen", "Almaty": "Kazakhstan", "Amman": "Jordan",
            "Anadyr": "Russia", "Aqtau": "Kazakhstan", "Aqtobe": "Kazakhstan",
            "Ashgabat": "Turkmenistan", "Atyrau": "Kazakhstan", "Baghdad": "Iraq",
            "Bahrain": "Bahrain", "Baku": "Azerbaijan", "Bangkok": "Thailand",
            "Barnaul": "Russia", "Beirut": "Lebanon", "Bishkek": "Kyrgyzstan",
            "Brunei": "Brunei", "Chita": "Russia", "Choibalsan": "Mongolia",
            "Colombo": "Sri Lanka", "Damascus": "Syria", "Dhaka": "Bangladesh",
            "Dili": "Timor-Leste", "Dubai": "UAE", "Dushanbe": "Tajikistan",
            "Famagusta": "Cyprus", "Gaza": "Palestine", "Hebron": "Palestine",
            "Ho_Chi_Minh": "Vietnam", "Hong_Kong": "Hong Kong", "Hovd": "Mongolia",
            "Irkutsk": "Russia", "Jakarta": "Indonesia", "Jayapura": "Indonesia",
            "Jerusalem": "Israel", "Kabul": "Afghanistan", "Kamchatka": "Russia",
            "Karachi": "Pakistan", "Kathmandu": "Nepal", "Khandyga": "Russia",
            "Kolkata": "India", "Krasnoyarsk": "Russia", "Kuala_Lumpur": "Malaysia",
            "Kuching": "Malaysia", "Kuwait": "Kuwait", "Macau": "Macau",
            "Magadan": "Russia", "Makassar": "Indonesia", "Manila": "Philippines",
            "Muscat": "Oman", "Nicosia": "Cyprus", "Novokuznetsk": "Russia",
            "Novosibirsk": "Russia", "Omsk": "Russia", "Oral": "Kazakhstan",
            "Phnom_Penh": "Cambodia", "Pontianak": "Indonesia", "Pyongyang": "North Korea",
            "Qatar": "Qatar", "Qostanay": "Kazakhstan", "Qyzylorda": "Kazakhstan",
            "Riyadh": "Saudi Arabia", "Sakhalin": "Russia", "Samarkand": "Uzbekistan",
            "Seoul": "South Korea", "Shanghai": "China", "Singapore": "Singapore",
            "Srednekolymsk": "Russia", "Taipei": "Taiwan", "Tashkent": "Uzbekistan",
            "Tbilisi": "Georgia", "Tehran": "Iran", "Thimphu": "Bhutan",
            "Tokyo": "Japan", "Tomsk": "Russia", "Ulaanbaatar": "Mongolia",
            "Urumqi": "China", "Ust-Nera": "Russia", "Vientiane": "Laos",
            "Vladivostok": "Russia", "Yakutsk": "Russia", "Yangon": "Myanmar",
            "Yekaterinburg": "Russia", "Yerevan": "Armenia"
        ]
        return mapping[city] ?? "Asia"
    }

    private func atlanticCountry(for city: String) -> String {
        let mapping: [String: String] = [
            "Azores": "Portugal", "Bermuda": "Bermuda", "Canary": "Spain",
            "Cape_Verde": "Cape Verde", "Faroe": "Faroe Islands", "Madeira": "Portugal",
            "Reykjavik": "Iceland", "South_Georgia": "South Georgia", "St_Helena": "Saint Helena",
            "Stanley": "Falkland Islands"
        ]
        return mapping[city] ?? "Atlantic"
    }

    private func europeCountry(for city: String) -> String {
        let mapping: [String: String] = [
            "Amsterdam": "Netherlands", "Andorra": "Andorra", "Astrakhan": "Russia",
            "Athens": "Greece", "Belgrade": "Serbia", "Berlin": "Germany",
            "Bratislava": "Slovakia", "Brussels": "Belgium", "Bucharest": "Romania",
            "Budapest": "Hungary", "Busingen": "Germany", "Chisinau": "Moldova",
            "Copenhagen": "Denmark", "Dublin": "Ireland", "Gibraltar": "Gibraltar",
            "Guernsey": "Guernsey", "Helsinki": "Finland", "Isle_of_Man": "Isle of Man",
            "Istanbul": "Turkey", "Jersey": "Jersey", "Kaliningrad": "Russia",
            "Kiev": "Ukraine", "Kirov": "Russia", "Lisbon": "Portugal",
            "Ljubljana": "Slovenia", "London": "UK", "Luxembourg": "Luxembourg",
            "Madrid": "Spain", "Malta": "Malta", "Mariehamn": "Åland Islands",
            "Minsk": "Belarus", "Monaco": "Monaco", "Moscow": "Russia",
            "Nicosia": "Cyprus", "Oslo": "Norway", "Paris": "France",
            "Podgorica": "Montenegro", "Prague": "Czech Republic", "Riga": "Latvia",
            "Rome": "Italy", "Samara": "Russia", "San_Marino": "San Marino",
            "Sarajevo": "Bosnia and Herzegovina", "Saratov": "Russia", "Simferopol": "Ukraine",
            "Skopje": "North Macedonia", "Sofia": "Bulgaria", "Stockholm": "Sweden",
            "Tallinn": "Estonia", "Tirane": "Albania", "Ulyanovsk": "Russia",
            "Uzhgorod": "Ukraine", "Vaduz": "Liechtenstein", "Vatican": "Vatican City",
            "Vienna": "Austria", "Vilnius": "Lithuania", "Volgograd": "Russia",
            "Warsaw": "Poland", "Zagreb": "Croatia", "Zaporozhye": "Ukraine",
            "Zurich": "Switzerland"
        ]
        return mapping[city] ?? "Europe"
    }

    private func indianCountry(for city: String) -> String {
        let mapping: [String: String] = [
            "Antananarivo": "Madagascar", "Chagos": "British Indian Ocean Territory",
            "Christmas": "Christmas Island", "Cocos": "Cocos Islands", "Comoro": "Comoros",
            "Kerguelen": "French Southern Territories", "Mahe": "Seychelles", "Maldives": "Maldives",
            "Mauritius": "Mauritius", "Mayotte": "Mayotte", "Reunion": "Réunion"
        ]
        return mapping[city] ?? "Indian Ocean"
    }

    private func pacificCountry(for city: String) -> String {
        let mapping: [String: String] = [
            "Apia": "Samoa", "Auckland": "New Zealand", "Bougainville": "Papua New Guinea",
            "Chatham": "New Zealand", "Chuuk": "Micronesia", "Easter": "Chile",
            "Efate": "Vanuatu", "Enderbury": "Kiribati", "Fakaofo": "Tokelau",
            "Fiji": "Fiji", "Funafuti": "Tuvalu", "Galapagos": "Ecuador",
            "Gambier": "French Polynesia", "Guadalcanal": "Solomon Islands", "Guam": "Guam",
            "Honolulu": "USA", "Kiritimati": "Kiribati", "Kosrae": "Micronesia",
            "Kwajalein": "Marshall Islands", "Majuro": "Marshall Islands", "Marquesas": "French Polynesia",
            "Midway": "USA", "Nauru": "Nauru", "Niue": "Niue",
            "Norfolk": "Norfolk Island", "Noumea": "New Caledonia", "Pago_Pago": "American Samoa",
            "Palau": "Palau", "Pitcairn": "Pitcairn Islands", "Pohnpei": "Micronesia",
            "Port_Moresby": "Papua New Guinea", "Rarotonga": "Cook Islands", "Saipan": "Northern Mariana Islands",
            "Tahiti": "French Polynesia", "Tarawa": "Kiribati", "Tongatapu": "Tonga",
            "Wake": "USA", "Wallis": "Wallis and Futuna"
        ]
        return mapping[city] ?? "Pacific"
    }
}
