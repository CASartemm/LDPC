clear;
Slots = load("slots_640.mat");
Slots = Slots.Slots;


%====================================================================
%====================================================================

for i=1:length(Slots(:,1))
    data(i,:) = demodqpsk_istar(Slots(i,21:end));
end

dataLen = length(data(1,1:end));
seqA = scrembler_istar([1 0 0 1 0 1 0 1 0 1 0 1 1 1 1], dataLen);                   
seqB = scrembler_istar([0 0 0 1 1 1 0 0 0 1 1 1 0 0 0], dataLen);

for i=1:length(data(:,1))
    for j = 1:length(data(1,:)) %пропускаем уникальное слово и не скремблируем его
       if (mod(j,2) == 1)
           data(i,j) = xor(data(i,j),seqA(fix(j/2)+1));
       else
           data(i,j) = xor(data(i,j),seqB(fix(j/2)  ));
       end
    end
    
end





% [data | ldpc] * H' = [00...00]
% 
% H = [P' | I]
% 
% H' = [P
%       I'];
% 
% data * P = LDPC * I', I' - ?


P = load("P_640_doc.mat");
P = P.P;

LdpcData = data(1:128,641:640+128);

for i = 1:128
    LdpcDoc(i,:) = mod(data(i,1:640)*P,2);   
end

for i = 1:128
    It(:,i) = gflineq( LdpcData, LdpcDoc(1:128,i));
end


figure;
imagesc(It');

H = [P' It']; 
figure;
imagesc(H);


%Далее нужно найти матрицу G
%G*H'=0
%[I Pg]*[Pdoc 
%         It]   = 0
%Pg = Pdoc*inv(It)

det(It); %Проверяем, что он не ноль. 
invIt = inv(gf(It));
invIt = double(invIt.x); %Находим обратную It

Pg = mod(P*invIt,2); %Находим Pg 
figure;
imagesc(Pg);


P_640_serch = load("P_640_serch.mat"); %Загружаем аналитически найденную матрицу для сравнения
P_640_serch = P_640_serch.P;

figure;
imagesc(P_640_serch);

figure;
imagesc(P_640_serch*3 - Pg); %ура!!!!

figure;
for i = 1:20
    for j = 1:4
        imagesc(Pg( (i-1)*32+1:i*32,(j-1)*32+1:j*32 ) ); 
        pause(1);
    end
end




