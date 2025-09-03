clear;

load("Slots.mat");
load("Slots_pi2.mat");
load("Slots_2pi2.mat");
load("Slots_3pi2.mat");


load("P1.mat");
load("P2.mat");
load("P3.mat");
load("P4.mat");



%====================================================================
%====================================================================
%====================================================================
%на оставшихся слотах делаю проверку того, что матрица P генерирует тот же
%LDPC довесок, что есть в сообщении
for i=641:1260
    data_check1(i-640,:) = demodqpsk(Slots(i,21:end));
    data_check2(i-640,:) = demodqpsk(Slots_pi2(i,21:end));
    data_check3(i-640,:) = demodqpsk(Slots_2pi2(i,21:end));
    data_check4(i-640,:) = demodqpsk(Slots_3pi2(i,21:end));
end

data_check1 = gf(data_check1); % перевод в поле Галуа
data_check2 = gf(data_check2);
data_check3 = gf(data_check3);
data_check4 = gf(data_check4);
P1 = gf(P1);
P2 = gf(P2);
P3 = gf(P3);
P4 = gf(P4);


H1 = gf([P1' eye(132)]);
counter1 = 0;
for i=1:length(data_check1(:,1))
    if ( H1*data_check1(i,:)' == gf(zeros(132,1))) %непосредственно сранение, что расчитал с помощью P и что передаётся в слотах
        counter1 = counter1 +1;
    else
        disp('error1')
    end
end

H2 = gf([P2' eye(132)]);
counter2 = 0;
for i=1:length(data_check2(:,1))
    if ( H2*data_check2(i,:)' == gf(zeros(132,1))) %непосредственно сранение, что расчитал с помощью P и что передаётся в слотах
        counter2 = counter2 +1;
    else
        disp('error2')
    end
end

H3 = gf([P3' eye(132)]);
counter3 = 0;
for i=1:length(data_check3(:,1))
    if ( H3*data_check3(i,:)' == gf(zeros(132,1))) %непосредственно сранение, что расчитал с помощью P и что передаётся в слотах
        counter3 = counter3 +1;
    else
        disp('error3')
    end
end

H4 = gf([P4' eye(132)]);
counter4 = 0;
for i=1:length(data_check4(:,1))
    if ( H4*data_check4(i,:)' == gf(zeros(132,1))) %непосредственно сранение, что расчитал с помощью P и что передаётся в слотах
        counter4 = counter4 +1;
    else
        disp('error4')
    end
end
