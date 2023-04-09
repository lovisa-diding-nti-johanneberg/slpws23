

def getNamesOfPlaces()
    result = db.execute("SELECT place FORM places")
    return result
end