from kiwipiepy import Kiwi
from kiwipiepy.utils import Stopwords

k = Kiwi()
s = "공격하기 위한것이 아니다"

#from htmldate import find_date

def getDate(url) -> str:
    # if(pd.isnull(url)):
    #     return(None)
    try:
        print("trying", url)
        ret = find_date(url)
    except:
        print("error!")
        return(None)
    return(ret)

#myurl = "https://www.straitstimes.com/asia/east-asia/united-airlines-avoids-listing-taiwan-hk-as-part-of-china-by-using-flexible"
#getDate(myurl)
