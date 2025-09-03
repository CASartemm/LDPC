function [data] = demodqpsk(slot)

data = zeros(1, 2*numel(slot));

for i=1:numel(slot)
        if (slot(i) ==  (1+1i*1))
            data(2*i - 1) = 1;
            data(2*i)     = 1;
        end 
        if (slot(i) ==  (1-1i*1))
            data(2*i - 1) = 1;
            data(2*i)     = 0;
        end
        if (slot(i) ==  (-1-1i*1))
            data(2*i - 1) = 0;
            data(2*i)     = 0;
        end
        if (slot(i) ==  (-1+1i*1))
            data(2*i - 1) = 0;
            data(2*i)     = 1;
        end
         
end
end

