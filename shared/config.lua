Config = {}

Config["JobName"] = "kwaliteitsmedewerker"

Config["Locaties"] = {}
Config["Locaties"]["StartJob"] = {coords = vector3(1218.646118, -1266.646118, 36.407349), heading = 181.417328}
Config["Locaties"]["SpawnVehicle"] = {coords = vec3(1206.632935, -1269.652710, 35.210938), heading = 172.913391}
Config["Locaties"]["DeleteVehicle"] = {coords = vec3(1206.632935, -1269.652710, 35.210938), heading = 172.913391}

Config["Tasks"] = {
    ["stoplicht"] = {
        label = "Zekering vervangen",
        notify = "Er moet een zekering worden vervangen!",
        notifyDone = "Je hebt de zekering vervangen!",
        reward = 300,
        locations = {
            vec3(350.347260, 157.714294, 103.082031),
        }
    },
    ["zendmast"] = {
        label = "Zendmast repareren",
        notify = "Een zendmast moet worden gerepareerd!",
        notifyDone = "Je hebt de zendmast gerepareerd!",
        reward = 250,
        locations = {
            vec3(-687.349426, -1397.683472, 5.414673),
        }
    },
    ["water"] = {
        label = "Waterkwaliteit meten",
        notify = "De waterkwaliteit moet worden gemeten!",
        notifyDone = "Je hebt de waterkwaliteit gemeten!",
        reward = 475,
        locations = {
            vec3(-760.668152, -1378.786865, 1.595581),
        }
    },
    ["satelliet"] = {
        label = "Satelietschotel repareren",
        notify = "Een satellietschotel moet worden gekalibreerd!",
        notifyDone = "Je hebt de satellietschotel gekalibreerd!",
        reward = 350,
        locations = {
            vec3(2000.940674, 2930.347168, 56.964111),
        }
    }
}