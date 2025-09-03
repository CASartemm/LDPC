classdef Scrembler
    
    properties
        polinom 
        initState 
        header %для какого заголовка этот скремблер
    end
    
    methods
          
        function seq = genSeq(obj, n) % n - длинна которую нужно сгенерить
                    
            register = obj.initState; %инициализируем сдвиговый регистр
            num_shift = 0; %итератор сдвига сдвигов
            %seq = zeros(1,n); %обнуление псевдослучайной последовательности 

            while (num_shift < n) 
                seq(num_shift+1) = register(end); %заполняем целевую последовательность для анализа
                % Вычисляем обратную связь (XOR между отводными битами)
                feedback_bit = 0;
                for i = 2:length(obj.polinom)
                   feedback_bit = xor(feedback_bit, register(i-1)*obj.polinom(i));
                end
                % Сдвиг регистра и добавление нового бита
                register = [feedback_bit, register(1:end-1)];
                num_shift = num_shift +1;
            end
       end
    end
end

