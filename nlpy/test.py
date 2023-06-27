from kiwipiepy import Kiwi
from kiwipiepy.utils import Stopwords

#k = Kiwi()
#s = "스웨리예공산당 핵 위협 장본인은 미국 인터네트에 게재"

from htmldate import find_date

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

myurl = "https://www.straitstimes.com/asia/east-asia/united-airlines-avoids-listing-taiwan-hk-as-part-of-china-by-using-flexible"
getDate(myurl)