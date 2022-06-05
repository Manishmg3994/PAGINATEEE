import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/categories_controller.dart';
import 'news_page.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'widget/news_card_widget.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final CategoriesController categoriesController =
      Get.put(CategoriesController());

  @override
  Widget build(BuildContext context) {
    return Container(
        color: Colors.white,
        child: Obx(() {
          if (categoriesController.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          } else {
            return DefaultTabController(
              length: categoriesController.categoriesList.length,
              child: Scaffold(
                appBar: AppBar(
                  backgroundColor: Colors.transparent,
                  elevation: 0,
                  flexibleSpace: TabBar(
                    tabs: categoriesController.categoriesList
                        .map((model) => tab(model.categoryName))
                        .toList(),
                    isScrollable: true,
                    labelColor: Colors.redAccent,
                    unselectedLabelColor: Colors.black,
                    indicatorSize: TabBarIndicatorSize.label,
                    indicatorColor: Colors.redAccent,
                  ),
                ),
                body: TabBarView(
                  controller: DefaultTabController.of(context),
                  children: categoriesController.categoriesList
                      .map((model) => Useless(
                            url: model.categoryUrl,
                          ))
                      .toList(), // TODOq
                ),
              ),
            );
          }
        }));
  }
}

Widget tab(String tabName) {
  return Tab(
    text: tabName,
  );
}

class Useless extends StatefulWidget {
  String? url;
  Useless({Key? key, this.url}) : super(key: key);

  @override
  State<Useless> createState() => _UselessState();
}

class _UselessState extends State<Useless> {
  final scrollcontroller = ScrollController();
  List<String> items = [];
  bool hasMore = true;
  int page = 1;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    initialfetch();
  }

  @override
  void dispose() {
    // TODO: implement dispose
    super.dispose();
    if (mounted) {
      scrollcontroller.dispose();
    }
  }

  initialfetch() {
    if (mounted) {
      fetch();
      scrollcontroller.addListener(() {
        var maxScroll = scrollcontroller.position.maxScrollExtent;
        var currentScroll = scrollcontroller.position.pixels;
        var delta = MediaQuery.of(context).size.height * 0.25;
        if (maxScroll - currentScroll <= delta) {
          //controller.position.maxScrollExtent == controller.offset
          fetch();
        }
      });
    }
  }

  Future fetch() async {
    if (isLoading) return;
    isLoading = true;
    const limit = 15;
    final url = Uri.parse("${widget.url}" + "?_limit=$limit&_page=$page");
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final List newItems = json.decode(response.body);
      setState(() {
        page++;
        isLoading = false;
        if (newItems.length < limit) {
          hasMore = false;
        }
        items.addAll(newItems.map<String>(
          (item) {
            final number = item["id"];
            return "Item $number";
          },
        ));
      });
    }
  }

  Future refresh() async {
    setState(() {
      isLoading = false;
      hasMore = true;
      page = 1;
      items.clear();
    });

    fetch();
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: refresh,
      child: ListView.builder(
        shrinkWrap: true,
        controller: scrollcontroller,
        padding: const EdgeInsets.all(8),
        itemCount: items.length + 1,
        itemBuilder: (context, index) {
          if (index < items.length) {
            final item = items[index];
            return ListTile(
              title: Text(item),
            );
          } else {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: hasMore
                  ? (items.isEmpty)
                      ? const Center(child: Text("No Data to Show"))
                      : const Center(child: CircularProgressIndicator())
                  : const Center(child: Text('No more items')),
            );
          }
        },
      ),
    );
  }
}
