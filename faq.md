## Where is this data coming from?

Each day I pull down the files from https://epistat.wiv-isp.be/covid/, to be more specific, I pull down the 'COVID19BE_CASES_MUNI_CUM' file.

Which contain for each municipality the

> Cumulative number of confirmed cases (combinations with zero cases are not shown

I then run some code to count what the actual delta is from the day before, and that gets filled out in the data.

## Is this data trustworthy?

I'm not making anything up, just downloading the CSV's and findin out the delta, it's only showing the confirmed cases as reported by Sciensano. These numbers sometimes get retroactively updated (you'll see a *-8?* in the table).

## Why?

I was not a fan of the Sciensano dashboard, I wanted to get a quick view of how each city was doing, to get a bit of perspective on what's happening.

## Why is the code so horrible?

I prefer the term 'Brutalist software'

## Is 'Brutalist software' a term you made up?

Yes

## Is 'Brutalist software' a fad?

I developed this in a very agile manner, where each sprint was about 5 minutes, and so the horrible shellscript expanded into a horrible website, and since it's doing almost nothing I threw away all best practices and went for stupid code that does stupid stuff in a stupid way, it's refreshing!

## Why don't you have any tests?

Like the orange one said: "The more you test, the more cases/errors you'll find"

## Why does it look so pretty?

That's all @maxvoltar

## Why is it not working/This is all wrong!

That's all @pjaspers's fault.
