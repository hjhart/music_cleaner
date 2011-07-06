def search(r,prefix,count,redis_key)
    results = []
    rangelen = 50 # This is not random, try to get replies < MTU size
    start = r.zrank(redis_key,prefix)
    return [] if !start
    while results.length != count
        range = r.zrange(redis_key,start,start+rangelen-1)
        start += rangelen
        break if !range or range.length == 0
        range.each {|entry|
            minlen = [entry.length,prefix.length].min
            if entry[0...minlen] != prefix[0...minlen]
                count = results.count
                break
            end
            if entry[-1..-1] == "*" and results.length != count
                results << entry[0...-1]
            end
        }
    end
    return results
end
