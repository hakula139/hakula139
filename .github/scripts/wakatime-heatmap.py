import argparse
import json
from calendar import month_abbr
from contextlib import closing
from datetime import date, timedelta
from http import HTTPStatus
from http.client import HTTPSConnection
from pathlib import Path
from xml.etree.ElementTree import Element, ElementTree, SubElement


# The public endpoint returns bucket identifiers in the total field.
BUCKETS = {
    0: 'Under 1 hr',
    10800: '1–3 hrs',
    28800: '4–8 hrs',
    36000: '9–10 hrs',
    43200: '11–12 hrs',
    43201: '13+ hrs',
}
THEMES = {
    'wakatime-heatmap.svg': (
        '#424a53',
        ('#eaeef2', '#b6d8ff', '#75b6fa', '#3688e1', '#1358a6', '#07376e'),
    ),
    'wakatime-heatmap-dark.svg': (
        '#c9d1d9',
        ('#21262d', '#183b63', '#255c91', '#3588cf', '#6bb1ed', '#b8dafa'),
    ),
}


def fetch_days() -> list[tuple[date, int]]:
    with closing(HTTPSConnection('api.wakatime.com', timeout=20)) as connection:
        connection.request('GET', '/api/v1/users/Hakula/insights/days/public')
        with connection.getresponse() as response:
            if response.status != HTTPStatus.OK:
                raise OSError(f'WakaTime returned HTTP {response.status}')
            data = json.load(response)['data']

    if (
        data['status'] != 'ok'
        or data['is_up_to_date'] is not True
        or data['range'] != 'last_year'
    ):
        raise ValueError("WakaTime has not finished updating the last year's activity")

    records = data['days']
    if not isinstance(records, list) or len(records) not in (365, 366):
        raise ValueError('Expected a full year of WakaTime activity')

    days = []
    for record in records:
        day = date.fromisoformat(record['date'])
        total = record['total']
        if days and day != days[-1][0] + timedelta(days=1):
            raise ValueError('WakaTime activity dates must be consecutive')
        if type(total) not in (int, float) or total not in BUCKETS:
            raise ValueError(f'Unknown WakaTime activity bucket for {day}')
        days.append((day, int(total)))

    return days


def text(svg: Element, label: str, x: int, y: int, **attributes: str) -> None:
    SubElement(svg, 'text', x=str(x), y=str(y), **attributes).text = label


def square(svg: Element, x: int, y: int, color: str) -> None:
    SubElement(
        svg, 'rect', x=str(x), y=str(y), width='11', height='11', rx='2', fill=color
    )


def render(
    days: list[tuple[date, int]], text_color: str, colors: tuple[str, ...]
) -> ElementTree:
    title = 'WakaTime activity over the last year'
    palette = dict(zip(BUCKETS, colors, strict=True))
    svg = Element(
        'svg',
        {
            'xmlns': 'http://www.w3.org/2000/svg',
            'width': '812',
            'height': '182',
            'viewBox': '0 0 812 182',
            'role': 'img',
            'aria-labelledby': 'title description',
            'font-family': 'system-ui, sans-serif',
            'font-size': '12',
            'fill': text_color,
        },
    )
    SubElement(svg, 'title', id='title').text = title
    SubElement(svg, 'desc', id='description').text = (
        f'Daily activity from {days[0][0]} to {days[-1][0]}. Each square is one day. '
        f'Colors represent time bands: {", ".join(BUCKETS.values())}.'
    )
    text(svg, title, 12, 21, **{'font-size': '16', 'font-weight': '600'})

    grid_x, grid_y, step = 44, 52, 14
    for row, label in ((1, 'Mon'), (3, 'Wed'), (5, 'Fri')):
        text(svg, label, 12, grid_y + row * step + 10)

    start = (days[0][0].weekday() + 1) % 7
    for offset, (day, total) in enumerate(days, start):
        week, row = divmod(offset, 7)
        x = grid_x + week * step
        if day.day == 1:
            text(svg, month_abbr[day.month], x, grid_y - 7)
        square(svg, x, grid_y + row * step, palette[total])

    for index, (total, label) in enumerate(BUCKETS.items()):
        x = 321 + index * 80
        square(svg, x, 163, palette[total])
        text(svg, label, x + 16, 173)

    return ElementTree(svg)


def main() -> None:
    parser = argparse.ArgumentParser(
        description='Render the public WakaTime activity heatmap.'
    )
    parser.add_argument('output_dir', type=Path)
    args = parser.parse_args()

    try:
        days = fetch_days()
    except (KeyError, OSError, TypeError, ValueError) as error:
        raise SystemExit(f'Could not load public WakaTime activity: {error}') from error

    args.output_dir.mkdir(parents=True, exist_ok=True)
    for filename, (text_color, colors) in THEMES.items():
        svg = render(days, text_color, colors)
        svg.write(args.output_dir / filename, encoding='utf-8')


if __name__ == '__main__':
    main()
