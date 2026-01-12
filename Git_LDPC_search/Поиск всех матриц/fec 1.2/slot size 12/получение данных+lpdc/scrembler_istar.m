       
function seq = scrembler_istar(initState, n) % n - длинна которую нужно сгенерить
            
    register = initState; %инициализируем сдвиговый регистр
    num_shift = 0; %итератор сдвига сдвигов
    %seq = zeros(1,n); %обнуление псевдослучайной последовательности 

    while (num_shift < n) 
        
        % Вычисляем обратную связь (XOR между отводными битами)
        % полином у Истара 13 и 15
        feedback_bit = xor(register(13), register(15)); 
        

        seq(num_shift+1) = feedback_bit; %заполняем целевую последовательность для анализа


        % Сдвиг регистра и добавление нового бита
        register = [feedback_bit, register(1:end-1)];
        num_shift = num_shift +1;
    end
end

