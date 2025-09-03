function [data] = uniqWord(slot)

data = "";

for i=1:20
        if (slot(i) ==  (1+1i*1))
            data = append(data, '++ ');
        end 
        if (slot(i) ==  (1-1i*1))
            data = append(data, '+- ');
        end
        if (slot(i) ==  (-1-1i*1))
            data = append(data, '-- ');
        end
        if (slot(i) ==  (-1+1i*1))
            data = append(data, '-+ ');
        end

        if (i == 5)
           data = append(data, '      '); 
        end
         
end

data = append(data, newline);
end

