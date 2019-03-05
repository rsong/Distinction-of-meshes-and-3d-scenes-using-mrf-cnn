function mrf = mrf4(x,viewclass,numsa,vring)
% x is the weight for each viewpoint;
% w is the weighting parameter vector;

prior=zeros(numsa,1);

for i=1:numsa
    neighbours=vring{i};
    num_neighbours=length(neighbours);
    pairdiff=zeros(num_neighbours,1);
    for j=1:length(neighbours)
        pairdiff(j)= (x(i)-x(neighbours(j))).^2;
    end
    prior(i)=sum(pairdiff);
end

energy=(x-viewclass(:)).^2+0.1*prior;%hyperparameter 0.1
mrf=sum(energy);
end