function infilereplace(intemplate,infile,substitutions)
    function checkreplace(line,sep,substitutions)
        key,val = split(line,sep);
        key_strip = strip(key)

        for (k,v) in substitutions
            if key_strip == k
                line = key * sep * " $v"
                @info "setting $k to: $v"
            end
        end
        return line
    end

    # read file in memory as intemplate can be the same as infile
    template = collect(readlines(intemplate))

    fout = open(infile,"w")
    for line in template
        comments = ""
        m = match(r" +!.*$",line)

        if m !== nothing
            # strip comment
            comments = m.match
            line = line[1:end-length(comments)]
        end

        if (length(line) == 0)
            # empty line
        elseif occursin("==",line)
            line = checkreplace(line,"==",substitutions)
        elseif occursin("=",line)
            line = checkreplace(line,"=",substitutions)
        end

        println(fout,line,comments)
    end

    close(fout)

    try
        pp = run(`diff $intemplate $infile`)
    catch
    end

end
